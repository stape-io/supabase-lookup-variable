const createRegex = require('createRegex');
const encodeUriComponent = require('encodeUriComponent');
const getAllEventData = require('getAllEventData');
const getContainerVersion = require('getContainerVersion');
const getRequestHeader = require('getRequestHeader');
const getType = require('getType');
const JSON = require('JSON');
const logToConsole = require('logToConsole');
const makeString = require('makeString');
const Promise = require('Promise');
const sendHttpRequest = require('sendHttpRequest');
const sha256Sync = require('sha256Sync');
const templateDataStorage = require('templateDataStorage');

/*==============================================================================
==============================================================================*/

const eventData = getAllEventData();

if (shouldExitEarly(eventData)) return;

return lookupSupabase().then(mapResponse);

/*==============================================================================
Vendor related functions
==============================================================================*/

function getUrl() {
  if (!data.projectUrl) return undefined;
  const baseUrl = data.projectUrl.replace(createRegex('/$'), '');
  const url = baseUrl + '/rest/v1/' + enc(data.tableName);
  const params = (data.queryConditions || []).map((item) => enc(item.key) + '=' + enc(item.value)).join('&');
  return params ? url + '?' + params : url;
}

function getOptions() {
  const headers = {
    'Content-Type': 'application/json',
    apikey: data.apiKey,
    Authorization: 'Bearer ' + data.apiKey
  };
  return { headers: headers, method: 'GET' };
}

function lookupSupabase() {
  const url = getUrl();
  if (!url) return Promise.create((resolve) => resolve('{}'));

  const options = getOptions();
  const cacheKey = data.storeResponse ? sha256Sync(url + JSON.stringify(options)) : '';
  if (data.storeResponse) {
    const cachedValue = templateDataStorage.getItemCopy(cacheKey);
    if (!!cachedValue) return Promise.create((resolve) => resolve(cachedValue));
  }

  log({
    Name: 'SupabaseLookup',
    Type: 'Request',
    EventName: 'StoreRead',
    RequestMethod: options.method,
    RequestUrl: url,
    RequestBody: options
  });

  return sendHttpRequest(url, options)
    .then((response) => {
      log({
        Name: 'SupabaseLookup',
        Type: 'Response',
        EventName: 'StoreRead',
        ResponseStatusCode: response.statusCode,
        ResponseHeaders: response.headers,
        ResponseBody: response.body
      });

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data.storeResponse) templateDataStorage.setItemCopy(cacheKey, response.body);
        return response.body;
      }
      return undefined;
    })
    .catch((error) => {
      log({
        Name: 'SupabaseLookup',
        Type: 'Message',
        EventName: 'StoreRead',
        Message: 'The request failed or timed out.',
        Reason: JSON.stringify(error)
      });
      return undefined;
    });
}

function mapResponse(bodyString) {
  if (!bodyString) return undefined;
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

/*==============================================================================
Helpers
==============================================================================*/

function shouldExitEarly(eventData) {
  const url = eventData.page_location || getRequestHeader('referer');
  if (url && url.lastIndexOf('https://gtm-msr.appspot.com/', 0) === 0) return true;
  return false;
}

function enc(data) {
  if (['null', 'undefined'].indexOf(getType(data)) !== -1) data = '';
  return encodeUriComponent(makeString(data));
}

function log(rawDataToLog) {
  const logDestinationsHandlers = {};
  if (determinateIsLoggingEnabled()) logDestinationsHandlers.console = logConsole;

  rawDataToLog.TraceId = getRequestHeader('trace-id');

  for (const logDestination in logDestinationsHandlers) {
    const handler = logDestinationsHandlers[logDestination];
    if (!handler) continue;

    const dataToLog = rawDataToLog;

    handler(dataToLog);
  }
}

function logConsole(dataToLog) {
  logToConsole(JSON.stringify(dataToLog));
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
