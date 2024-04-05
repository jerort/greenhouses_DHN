function [TMY] = API_PVGIS_TMY(latitud,longitud)
% https://joint-research-centre.ec.europa.eu/pvgis-photovoltaic-geographical-information-system/getting-started-pvgis/api-non-interactive-service_en

% Import HTTP interface packages
import matlab.net.*
import matlab.net.http.*
import matlab.net.http.fields.*


% Setup request
requestUri = URI(strcat('https://re.jrc.ec.europa.eu/api/tmy?lat=',...
                        string(latitud),'&lon=',string(longitud),...
                        '&outputformat=json'));
request = RequestMessage;
request.Header = HeaderField('Content-Type','application/json');
request.Method = 'GET';

% Send request
response = request.send(requestUri);

%% Tratamiento
TMY.G = cell2mat({response.Body.Data.outputs.tmy_hourly.G_h_}');
TMY.T = cell2mat({response.Body.Data.outputs.tmy_hourly.T2m}');
TMY.HR = cell2mat({response.Body.Data.outputs.tmy_hourly.RH}');
TMY.VV = cell2mat({response.Body.Data.outputs.tmy_hourly.WS10m}');
TMY.Patm = cell2mat({response.Body.Data.outputs.tmy_hourly.SP}');
TMY.time = cell2mat({response.Body.Data.outputs.tmy_hourly.time_UTC_}');
end

