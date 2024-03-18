import { Logger } from '@aws-lambda-powertools/logger';

const logger = new Logger();

export const handler = async (event) => {
  try {

    logger.info('Checking user token');
    /**
     * The token should be validated against the identity provider.
     * This is an example authorizer implementation.
     */
    return {
      isAuthorized: event.authorizationToken ? true : false
    };
  } catch (error) {
    logger.error('Error | Authorized: false', { error });
    return {
      isAuthorized: false
    };
  }
};