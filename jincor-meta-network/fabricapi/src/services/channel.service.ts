import * as path from 'path';
import * as FabricClient from 'fabric-client/lib/Client.js';
import config from '../config';
import { injectable, inject } from 'inversify';

import { Logger } from '../logger';
import { FabricClientService } from './fabric.service';
import { IdentificationData } from './identify.service';

// IoC
export const ChannelServiceType = Symbol('ChannelServiceType');

// Exceptions
export class ChannelServiceException extends Error {}
export class InvalidArgumentException extends ChannelServiceException { }
export class InvalidEndorsementException extends ChannelServiceException { }
export class BroadcastingException extends ChannelServiceException { }

/**
 * ChannelService
 */
@injectable()
export class ChannelService {
  private logger = Logger.getInstance('CHANNEL_SERVICE');

  private channelName: string;
  private fabricService: any;
  private identityData: IdentificationData;

  /**
   * Set instance context.
   * @param fabricService
   */
  setContext(fabricService: FabricClientService, identityData: IdentificationData, channelName: string): ChannelService {
    this.fabricService = fabricService;
    this.channelName = channelName;
    this.identityData = identityData;
    return this;
  }

  private parseChaincodeId(chaincodeId: string): Array<string> {
    const parts = chaincodeId.split(':');
    if (!parts[0] || !parts[1]) {
      throw new InvalidArgumentException('Invalid chaincodeId');
    }
    return parts;
  }

  /**
   * @param chaincodeId
   * @param chaincodePath
   * @param chaincodeVersion
   * @param peers
   */
  async deployChaincode(chaincodeId: string, chaincodePath: string, peers: Array<string>): Promise<any> {
    process.env.GOPATH = config.channelService.goSrcPath;

    this.logger.verbose('Deploy chaincode %s', arguments);

    if (!chaincodePath) {
      throw new InvalidArgumentException('Invalid chaincodePath');
    }

    const [ chaincodeName, chaincodeVersion ] = this.parseChaincodeId(chaincodeId);

    return await this.fabricService.getClient().installChaincode({
      targets: peers,
      chaincodeName,
      chaincodePath,
      chaincodeVersion
    });
  }

  /**
   * @param channelName
   * @param chaincodeId
   * @param chaincodeVersion
   * @param args
   * @param peers
   * @param policy
   */
  async initiateChaincode(
    chaincodeId: string,
    args: Array<string>,
    peers: Array<string>,
    policy: any = []
  ): Promise<any> {
    this.logger.verbose('Initiate chaincode %s', arguments);

    const [ chaincodeName, chaincodeVersion ] = this.parseChaincodeId(chaincodeId);

    const client = this.fabricService.getClient();

    console.log(await client.getUserContext(this.identityData.username));

    const transactionId = client.newTransactionID();
    const channel = client.getChannel(this.channelName);

    await channel.initialize();

    this.logger.verbose('Send transaction proposal');
    const resultOfProposal = await channel.sendInstantiateProposal({
      chaincodeName,
      chaincodeVersion,
      args: args || [],
      txId: transactionId,
      targets: peers,
      'endorsement-policy': policy
    });

    const [proposalResponses, proposal] = resultOfProposal;

    this.checkEndorsementPolicyOfResponse(proposalResponses);

    await this.broadcastTransaction(this.channelName, proposalResponses, proposal);
  }

  /**
   * @param channelName
   */
  async getChannel(channelName) {
    return await this.fabricService.getClient().getChannel(channelName);
  }

  /**
   * @param channelName
   * @param chaincodeId
   * @param chaincodeVersion
   * @param method
   * @param args
   * @param transientMap
   * @param peers
   * @param commitTransaction
   * @param policy
   */
  async callChaincode(
    chaincodeId: string,
    method: string,
    args: Array<string>,
    transientMap: any,
    peers: Array<string>,
    commitTransaction: boolean = false
  ): Promise<any> {
    this.logger.verbose('Call chaincode %s', arguments);

    if (!method) {
      throw new InvalidArgumentException('Invalid method');
    }

    const [ chaincodeName, chaincodeVersion ] = this.parseChaincodeId(chaincodeId);

    const transactionId = this.fabricService.getClient().newTransactionID();
    const channel = await this.getChannel(this.channelName);

    this.logger.verbose('Send transaction proposal');
    const resultOfProposal = channel.sendTransactionProposal({
      chaincodeName,
      chaincodeVersion,
      fcn: method,
      args,
      chainId: this.channelName,
      transientMap: transientMap || undefined,
      txId: transactionId,
      targets: peers
    });

    const [proposalResponses, proposal] = resultOfProposal;

    this.checkEndorsementPolicyOfResponse(proposalResponses);

    if (commitTransaction) {
      await this.broadcastTransaction(this.channelName, proposalResponses, proposal);
    }
  }

  /**
   * @param proposalResponses
   */
  checkEndorsementPolicyOfResponse(proposalResponses: any) {
    let endorsementSatisfied = true;

    this.logger.verbose('Check endorsement policy in the response');

    for (let i in proposalResponses) {
      let result = false;
      if (
        proposalResponses &&
        proposalResponses[i].response &&
        proposalResponses[i].response.status === 200
      ) {
        result = true;
      }
      endorsementSatisfied = endorsementSatisfied && result;
    }

    if (!endorsementSatisfied) {
      this.logger.error('Endorsement policy is not satisfied');
      throw new InvalidEndorsementException('Chaincode call failed');
    }
  }

  /**
   * @param channelName
   * @param proposalResponses
   * @param proposal
   */
  async broadcastTransaction(channelName: string, proposalResponses: any, proposal: any) {
    this.logger.verbose('Send transaction to orderer');

    const channel = await this.getChannel(channelName);

    const broadcastResult = await channel.sendTransaction({
      proposalResponses,
      proposal
    });

    if (broadcastResult[0].status !== 'SUCCESS') {
      this.logger.error('Failed to broadcast a transaction by orderer');
      throw new BroadcastingException('Broadcast failed');
    }
  }
}
