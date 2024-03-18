/**
 * @param ctx - Contextual information for your resolver invocation.
 * @returns - A data source request object.
 */
export function request(ctx) {

  return {
    payload: { status: "OK", message: "Authorized successfully" },
  };
}

/**
 * This function handles the response from the data source.
 * @param ctx - Contextual information for your resolver invocation.
 */
export function response(ctx) {
  const { error, result, request } = ctx;
  const requestId = request.headers['x-amzn-requestid'];

  if (error) {
    util.error(`Error processing request: RequestId:${requestId}`, error.type);
  }
  return result;
}
