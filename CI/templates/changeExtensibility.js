var configurations = require('./configurations.json');

if(configurations.moduleName == null) {
    throw new Error("Missing moduleName configuration in package.json");
}

if(process.env.npm_config_repositoryURL == null || process.env.npm_config_branch == null || process.env.npm_config_environment == null) {
    throw new Error("Missing repositoryURL, branch, environment arguments");
}

if(process.env.npm_config_authentication == null) {
    throw new Error("Missing authentication argument");
}

if(process.env.npm_config_versionLifeTimeEnvironment == null) {
    throw new Error("Missing lifetime environment argument");
}

var extensibilityChangeJson = readJSONFile("extensibilityConfiguration.json");

if(extensibilityChangeJson == null) {
    throw new Error("Missing extensibilityConfiguration.json file");
}
var XMLHttpRequest = require("xmlhttprequest").XMLHttpRequest;

var repository = process.env.npm_config_repositoryURL;
var branch = process.env.npm_config_branch;
var environment = process.env.npm_config_environment;
var moduleName = configurations.moduleName ;
var basicAuthentication = process.env.npm_config_authentication;
var pluginName = configurations.lifetimeVersion.applicationName;
var lifeTimeEnvironment = process.env.npm_config_versionLifeTimeEnvironment; 

var url = "https://" + environment + "/CodeUpdater/rest/Bulk/ExtensabilityUpdate";
var query = "?Environment=" + lifeTimeEnvironment + "&ApplicationName=" + pluginName;
var newVersionURL = "https://" + environment + "/PipelineAPI/rest/Bulk/getApplicationNewVersion" + query;

var lifeTimeRequest = new XMLHttpRequest();
lifeTimeRequest.open("GET", newVersionURL, false);
lifeTimeRequest.setRequestHeader("Authorization", basicAuthentication);
lifeTimeRequest.setRequestHeader("Content-Type", "application/json");
lifeTimeRequest.send();

var lifeTimeResponse;

if(lifeTimeRequest.status == 200) {
    var response = lifeTimeRequest.responseText;
    lifeTimeResponse = JSON.parse(response);
} else {
    throw new Error("Network Error:" + JSON.stringify(lifeTimeRequest));
}

extensibilityChangeJson.plugin.url = repository+"#"+branch;
extensibilityChangeJson.plugin.pluginName = lifeTimeResponse.PluginName;
extensibilityChangeJson.plugin.pluginVersion = lifeTimeResponse.PluginVersion;

var extensibilityChangeString = JSON.stringify(extensibilityChangeJson);
var buffer = new Buffer.from(extensibilityChangeString);
var base64 = buffer.toString('base64');

var body = [{
    "ModuleName": moduleName,
    "Content": base64
}];

console.log(
    "Started changing extensibility in module " + moduleName + 
    ".\n -- Extensibility will be configured to: " + repository+"#"+branch +
    "\nin environment:" + environment
);

var request = new XMLHttpRequest();
request.open("POST", url, false);
request.setRequestHeader("Authorization", basicAuthentication);
request.setRequestHeader("Content-Type", "application/json");
request.send(JSON.stringify(body));

if(request.status == 200) {
    console.log("Successfully updated OML");
} else {
    throw new Error("Network Error:" + JSON.stringify(request));
}

function readJSONFile(file) {
    var fs = require('fs');
    var data = fs.readFileSync(file, 'utf8');
    return JSON.parse(data);
}