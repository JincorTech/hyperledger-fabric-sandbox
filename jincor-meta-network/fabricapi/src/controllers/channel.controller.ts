import { Request, Response } from 'express';
import { inject, injectable } from 'inversify';
import { controller, httpDelete, httpPost } from 'inversify-express-utils';
import 'reflect-metadata';

import { FabricClientService } from '../services/fabric.service';
import { ChannelServiceType, ChannelService } from '../services/channel.service';
import { responseAsUnbehaviorError } from '../helpers/responses';

/**
 * ChannelsController resource
 */
@injectable()
@controller(
  '/api/channels/:channelname/chaincodes/:chaincodeid',
  'AuthMiddleware'
)
export class ChannelsController {

  constructor(
    @inject(ChannelServiceType) private channelService: ChannelService
  ) {
  }

  private setChannelServiceContext(req: Request) {
    this.channelService.setContext(FabricClientService.createFromRequest(req), req['tokenDecoded'], req.param('channelname'));
  }

  @httpPost(
    '/actions/deploy',
    'ChannelDeployChaincodeRequestValidator'
  )
  async deployChaincode(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setChannelServiceContext(req);

      const result = await this.channelService.deployChaincode(
        req.param('chaincodeid'),
        req.body.path,
        req.body.peers
      );

      // @TODO: add more verbose information
      res.json(result);
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }

  @httpPost(
    '/actions/initiate',
    'ChannelInitiateChaincodeRequestValidator'
  )
  async initiateChaincode(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setChannelServiceContext(req);

      const result = await this.channelService.initiateChaincode(
        req.param('chaincodeid'),
        req.body.args,
        req.body.peers
      );

      // @TODO: add more verbose information
      res.json(result);
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }

  @httpPost(
    '/actions/call',
    'ChannelCallChaincodeRequestValidator'
  )
  async callChaincode(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setChannelServiceContext(req);

      const result = await this.channelService.callChaincode(
        req.param('chaincodeid'),
        req.body.method,
        req.body.args,
        req.body.transientMap,
        req.body.peers,
        req.body.commitTransaction
      );

      // @TODO: add more verbose information
      res.json(result);
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }

}
