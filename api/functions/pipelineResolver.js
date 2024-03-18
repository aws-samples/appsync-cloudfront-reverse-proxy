/**
 * AppSync resolver: implements before and after business logic for your pipeline
 * Find more samples and templates at https://github.com/aws-samples/aws-appsync-resolver-samples
 */

import { util } from '@aws-appsync/utils';

/**
 * Called before the request function of the first AppSync function in the pipeline.
 * @param ctx The context object that holds contextual information about the function invocation.
 */
export function request(ctx) {
  ctx.stash.executionStart = util.time.nowEpochMilliSeconds();
  return {};
}
/**
 * Called after the response function of the last AppSync function in the pipeline.
 * @param  ctx The context object that holds contextual information about the function invocation.
 */
export function response(ctx) {
  const duration = util.time.nowEpochMilliSeconds() - ctx.stash?.executionStart;
  console.log(`METRICS|EXECUTION_DURATION|${ctx.info?.parentTypeName}.${ctx.info?.fieldName}|${duration}ms`);
  return ctx.prev.result;
}
