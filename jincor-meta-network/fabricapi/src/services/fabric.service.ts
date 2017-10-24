import { Request } from 'express';
import * as FabricClient from 'fabric-client/lib/Client.js';

import config from '../config';

// Exceptions
export class FabricClientException extends Error { }
export class InvalidArgumentException extends FabricClientException { }

/**
 * Service Wrapper for Fabric Client SDK.
 */
export class FabricClientService {
  private client;
  private isAdmin;
  private mspId;

  /**
   * Initiate user identification
   * @param username
   * @param role
   * @param mspId
   */
  constructor(username, role, mspId) {
    this.isAdmin = role === 'admin';
    this.mspId = mspId;
    this.client = FabricClient.loadFromConfig(config.network.filePath);
  }

  /**
   * Initiate from request
   * @param req
   */
  static createFromRequest(req: Request): FabricClientService {
    const decoded = req['tokenDecoded'];
    if (!decoded) {
      throw new InvalidArgumentException('There is no tokenDecoded in the request');
    }

    return new FabricClientService(decoded.username, decoded.role, decoded.mspId);
  }

  /**
   * Get native fabric client SDK
   */
  getClient(): any {
    return this.client;
  }
}
