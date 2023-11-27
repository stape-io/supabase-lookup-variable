const sendHttpRequest = require('sendHttpRequest');
const encodeUri = require('encodeUri');
const JSON = require('JSON');
const templateDataStorage = require('templateDataStorage');
const Promise = require('Promise');
const sha256Sync = require('sha256Sync');
const logToConsole = require('logToConsole');
const getRequestHeader = require('getRequestHeader');
const getContainerVersion = require('getContainerVersion');

const isLoggingEnabled = determinateIsLoggingEnabled();
const traceId = isLoggingEnabled ? getRequestHeader('trace-id') : undefined;

return getResponseBody().then(mapResponse);

function getUrl() {
  const url = data.projectUrl + '/rest/v1/' + encodeUri(data.tableName);
  const params = (data.queryConditions || []).map((item) => item.key + '=' + item.value).join('&');
  return params ? url + '?' + params : url;
}

function getOptions() {
  const headers = {
    'Content-Type': 'application/json',
    apikey: data.apiKey,
    Authorization: 'Bearer ' + data.apiKey,
  };
  return { headers: headers, method: 'GET' };
}

function mapResponse(bodyString) {
  const body = JSON.parse(bodyString);
  if (!data.documentPath) return body;
  const keys = data.documentPath.trim().split('.');
  let value = body;
  for (let i = 0; i < keys.length; i++) {
    const key = keys[i];
    if (!value || !key) break;
    value = value[key];
  }
  return value;
}

function getResponseBody() {
  const url = getUrl();
  const options = getOptions();
  const cacheKey = data.storeResponse ? sha256Sync(url + JSON.stringify(options)) : '';
  if (data.storeResponse) {
    const cachedValue = templateDataStorage.getItemCopy(cacheKey);
    if (cachedValue) return Promise.create((resolve) => resolve(cachedValue));
  }
  if (isLoggingEnabled) {
    logToConsole(
      JSON.stringify({
        Name: 'SupabaseLookup',
        Type: 'Request',
        TraceId: traceId,
        EventName: 'purchase',
        //TODO change event name
        RequestMethod: options.method,
        RequestUrl: options.url,
        RequestBody: options,
      })
    );
  }
  return sendHttpRequest(url, options).then((response) => {
    if (isLoggingEnabled) {
      logToConsole(
        JSON.stringify({
          Name: 'SupabaseLookup',
          Type: 'Response',
          TraceId: traceId,
          EventName: 'CreateOrUpdateContact',
          ResponseStatusCode: response.statusCode,
          ResponseHeaders: response.headers,
          ResponseBody: response.body,
        })
      );
    }
    if (data.storeResponse) templateDataStorage.setItemCopy(cacheKey, response.body);
    return response.body;
  });
}
function determinateIsLoggingEnabled() {
  const containerVersion = getContainerVersion();
  const isDebug = !!(containerVersion && (containerVersion.debugMode || containerVersion.previewMode));

  if (!data.logType) {
    return isDebug;
  }

  if (data.logType === 'no') {
    return false;
  }

  if (data.logType === 'debug') {
    return isDebug;
  }

  return data.logType === 'always';
}
