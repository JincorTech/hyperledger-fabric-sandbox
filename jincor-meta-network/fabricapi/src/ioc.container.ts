import { interfaces as InversifyInterfaces, Container } from 'inversify';
import { interfaces, TYPE } from 'inversify-express-utils';
import * as express from 'express';

import config from './config';

import * as commonMiddlewares from './middlewares/common';
import * as identify from './services/identify.service';
import * as certauth from './services/certauth.service';
import * as channel from './services/channel.service';
import * as fabric from './services/fabric.service';

import { AuthController } from './controllers/auth.controller';
import { ChannelsController } from './controllers/channel.controller';
import { CertAuthController } from './controllers/certauth.controller';
import * as validators from './middlewares/requests';

let container = new Container();

// services
container.bind<identify.BearerTokenService>(identify.BearerTokenServiceType)
  .to(identify.JwtBearerTokenService);

container.bind<identify.IdentificationService>(identify.IdentificationServiceType)
  .to(identify.FileIdentificationService);

container.bind<identify.AuthenticationService>(identify.AuthenticationServiceType)
  .to(identify.StandardAuthenticationService);

container.bind<certauth.CertificateAuthorityService>(certauth.CertificateAuthorityServiceType)
  .to(certauth.CertificateAuthorityService);

container.bind<channel.ChannelService>(channel.ChannelServiceType)
  .to(channel.ChannelService);

// middlewares
container.bind<commonMiddlewares.AuthMiddleware>(commonMiddlewares.AuthMiddlewareType)
  .to(commonMiddlewares.AuthMiddleware);

const authMiddleware = container
  .get<commonMiddlewares.AuthMiddleware>(commonMiddlewares.AuthMiddlewareType);

// request validators
container.bind<express.RequestHandler>('AuthLoginRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.authLoginRequest(req, res, next)
);
container.bind<express.RequestHandler>('CertAuthEnrollRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.certAuthEnrollRequestValidator(req, res, next)
);
container.bind<express.RequestHandler>('CertAuthEnrollExistsRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.certAuthEnrollExistsRequestValidator(req, res, next)
);
container.bind<express.RequestHandler>('CertAuthRegisterRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.certAuthRegisterRequestValidator(req, res, next)
);

container.bind<express.RequestHandler>('ChannelDeployChaincodeRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.channelDeployChaincodeRequest(req, res, next)
);
container.bind<express.RequestHandler>('ChannelInitiateChaincodeRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.channelInitiateChaincodeRequest(req, res, next)
);
container.bind<express.RequestHandler>('ChannelCallChaincodeRequestValidator').toConstantValue(
  (req: any, res: any, next: any) => validators.channelCallChaincodeRequest(req, res, next)
);

/* istanbul ignore next */
container.bind<express.RequestHandler>('AuthMiddleware').toConstantValue(
 (req: any, res: any, next: any) => authMiddleware.execute(req, res, next)
);

// controllers
container.bind<interfaces.Controller>(TYPE.Controller).to(AuthController).whenTargetNamed('AuthController');
container.bind<interfaces.Controller>(TYPE.Controller).to(CertAuthController).whenTargetNamed('CertAuthController');
container.bind<interfaces.Controller>(TYPE.Controller).to(ChannelsController).whenTargetNamed('ChannelsController');

export { container };