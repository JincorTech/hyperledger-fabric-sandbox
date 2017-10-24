import * as fs from 'fs';
import * as User from 'fabric-client/lib/User.js';
import * as FabricClient from 'fabric-client/lib/Client.js';
import * as FabricCaClient from 'fabric-ca-client/lib/FabricCAClientImpl.js';
import { injectable, inject } from 'inversify';

import { Logger } from '../logger';
import { IdentificationData } from './identify.service';
import { FabricClientService } from './fabric.service';

// IoC
export const CertificateAuthorityServiceType = Symbol(
  'CertificateAuthorityServiceType'
);

// Exceptions
export class CertificateAuthorityException extends Error {}
export class InvalidArgumentException extends CertificateAuthorityException {}
export class NotFoundException extends CertificateAuthorityException {}

// types

/**
 * Attribute passed to the certificate as OID 1.2.3.4.5.6.7.8.1
 */
interface EnrollAttribute {
  name: string;
  value: string;
  required?: boolean;
}

/**
 * CertificateAuthorityService to work with certificate enrollment.
 */
@injectable()
export class CertificateAuthorityService {
  private isCredentialStoresInitialized: boolean = false;
  private logger = Logger.getInstance('CERTIFICATE_AUTHORITY');
  private fabricService: any;
  private identityData: IdentificationData;

  /**
   * Set instance context.
   * @param fabricService
   */
  setContext(
    fabricService: FabricClientService,
    identityData: IdentificationData
  ) {
    this.fabricService = fabricService;
    this.identityData = identityData;
    return this;
  }

  private async initCredentialsStores(): Promise<void> {
    if (this.isCredentialStoresInitialized) {
      return;
    }

    this.logger.verbose('Initiate credential stores');

    await this.fabricService.getClient().initCredentialStores();
    this.isCredentialStoresInitialized = true;
  }

  private async getCa() {
    const caClient = this.fabricService.getClient().getCertificateAuthority();
    if (!caClient) {
      this.logger.error('CA not found');
      throw new NotFoundException('CA not found');
    }
    return caClient;
  }

  /**
   * Get certificate for the user.
   *
   * @param username
   * @param password
   * @param affiliation
   * @param attrs
   */
  async enroll(
    username: string,
    password: string,
    affiliation: string,
    attrs?: Array<EnrollAttribute>
  ): Promise<User> {
    this.logger.verbose('Enroll certificate for %s', username);

    if (!username) {
      throw new InvalidArgumentException('Invalid username');
    }
    if (!password) {
      throw new InvalidArgumentException('Invalid password');
    }

    await this.initCredentialsStores();

    const caClient = await this.getCa();

    let enrollment = await caClient.enroll({
      enrollmentID: username,
      enrollmentSecret: password,
      affiliation,
      attr_reqs: attrs || []
    });

    this.logger.verbose('Set up crypto environment for user %s', username);

    let userMember = new User(username);
    userMember.setCryptoSuite(this.fabricService.getClient().getCryptoSuite());
    await userMember.setEnrollment(
      enrollment.key,
      enrollment.certificate,
      this.identityData.mspId
    );

    await this.fabricService.getClient().setUserContext(userMember);

    return userMember;
  }

  /**
   * Enroll new certificate from the existing keys pair.
   *
   * @param username
   * @param mspid
   * @param privateKeyPath
   * @param signedCertPath
   */
  async enrollFromExistingKeys(
    username: string,
    privateKeyPath: string,
    signedCertPath: string
  ): Promise<User> {
    this.logger.verbose(
      'Enroll certificate from exisiting keys for %s',
      username
    );

    // @TODO: Validate args
    if (!username) {
      throw new InvalidArgumentException('Invalid username');
    }
    if (!privateKeyPath) {
      throw new InvalidArgumentException('Invalid privateKeyPath');
    }
    if (!signedCertPath) {
      throw new InvalidArgumentException('Invalid signedCertPath');
    }

    const newUser = await this.fabricService.getClient().createUser({
      username,
      mspid: this.identityData.mspId,
      cryptoContent: {
        privateKeyPath: fs.readFileSync(privateKeyPath, { encoding: 'utf8' }),
        signedCertPath: fs.readFileSync(signedCertPath, { encoding: 'utf8' })
      }
    });

    return newUser;
  }

  /**
   * Register a new user in the CA for future cert. enroll.
   *
   * @param adminUser
   * @param role
   * @param username
   * @param password
   * @param affiliation
   * @param attrs
   */
  async register(
    role: string,
    username: string,
    password: string,
    affiliation: string,
    attrs?: Array<EnrollAttribute>
  ): Promise<string> {
    this.logger.verbose('Register new user %s', username);

    if (!role) {
      throw new InvalidArgumentException('Invalid role');
    }
    if (!username) {
      throw new InvalidArgumentException('Invalid username');
    }
    if (!password) {
      throw new InvalidArgumentException('Invalid password');
    }

    const caClient = await this.getCa();

    this.logger.verbose('Load sign identity for %s', this.identityData.username);
    const signIdent = await this.fabricService
      .getClient()
      .loadUserFromStateStore(this.identityData.username);

    this.logger.verbose('Register %s', username);
    const userSecret = await caClient.register(
      {
        enrollmentID: username,
        enrollmentSecret: password || undefined,
        role,
        affiliation,
        attrs: attrs || []
      },
      signIdent
    );

    return userSecret || password;
  }
}
