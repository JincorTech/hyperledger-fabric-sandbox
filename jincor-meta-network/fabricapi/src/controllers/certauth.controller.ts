import { Request, Response } from 'express';
import { inject, injectable } from 'inversify';
import { controller, httpDelete, httpPost } from 'inversify-express-utils';
import 'reflect-metadata';

import { FabricClientService } from '../services/fabric.service';
import { CertificateAuthorityServiceType, CertificateAuthorityService } from '../services/certauth.service';
import { responseAsUnbehaviorError } from '../helpers/responses';

/**
 * CertAuthController resource
 */
@injectable()
@controller(
  '/api/cert-auths',
  'AuthMiddleware'
)
export class CertAuthController {

  constructor(
    @inject(CertificateAuthorityServiceType) private certAuthService: CertificateAuthorityService
  ) {
  }

  private setCertAuthServiceContext(req: Request) {
    this.certAuthService.setContext(FabricClientService.createFromRequest(req), req['tokenDecoded']);
  }

  @httpPost(
    '/users/actions/enroll',
    'CertAuthEnrollRequestValidator'
  )
  async enroll(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setCertAuthServiceContext(req);

      const enrollResult = await this.certAuthService.enroll(
        req.body.username,
        req.body.password,
        req.body.affiliation
      );

      // @TODO: add more verbose information
      res.json({
        username: req.body.username,
        isEnrolled: !!enrollResult
      });
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }

  @httpPost(
    '/users/actions/enroll-existing',
    'CertAuthEnrollExistsRequestValidator'
  )
  async enrollExisting(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setCertAuthServiceContext(req);

      const enrollResult = await this.certAuthService.enrollFromExistingKeys(
        req.body.username,
        req.body.privateKeyPath,
        req.body.publicKeyPath
      );

      // @TODO: add more verbose information
      res.json({
        username: req.body.username,
        isEnrolled: !!enrollResult
      });
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }

  @httpPost(
    '/users/actions/register',
    'CertAuthRegisterRequestValidator'
  )
  async register(
    req: Request,
    res: Response
  ): Promise<void> {
    try {
      this.setCertAuthServiceContext(req);

      const registerResult = await this.certAuthService.register(
        req.body.role,
        req.body.username,
        req.body.password,
        req.body.affiliation
      );

      // @TODO: add more verbose information
      res.json({
        username: req.body.username,
        isRegistered: !!registerResult
      });
    } catch (error) {
      responseAsUnbehaviorError(res, error);
    }
  }
}