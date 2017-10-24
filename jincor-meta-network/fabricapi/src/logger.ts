import { inspect } from 'util';
import * as winston from 'winston';
import config from './config';

export const newConsoleTransport = () => new (winston.transports.Console)({
  timestamp: true,
  json: config.logging.format === 'json',
  colorize: config.logging.colorize
});

/**
 * Logger
 */
export class Logger extends winston.Logger {
  private static loggers: any = {};

  /**
   * Get logger with name prefixed
   * @param name
   */
  public static getInstance(name: string): Logger {
    name = name || '';
    if (this.loggers[name]) {
      return this.loggers[name];
    }

    const logger = this.loggers[name] = new Logger(name);
    const originalLog = logger.log;
    // monkey-patch
    logger.log = function() {
      const args = Array.prototype.slice.call(arguments);
      args[1] = `[${name}] ${args[1]}`;
      return originalLog.apply(this, args);
    };
    return logger;
  }

  private constructor(private name: string) {
    super({
      level: config.logging.level,
      transports: [newConsoleTransport()]
    });
  }
}
