const sendHttpRequest = require('sendHttpRequest');
const encodeUri = require('encodeUri');
const JSON = require('JSON');

const url = getUrl();
const options = getOptions();

return sendHttpRequest(url, options).then(getResult);

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

function getResult(response) {
  const body = JSON.parse(response.body);
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
