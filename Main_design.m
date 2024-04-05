clear
clc
close all

tic
%% Cargar datos
aristas = loadjson('aristas.json');
vertices = loadjson('vertices.json');
load('conexiones.mat')  %no uploaded to GithUB due to size. Can be generated from Main.m
conexiones = removevars(conexiones,{'Q_cal','Q_den_cal'});
load('curva.mat')
Q_dem = curva;

%Se genera la demanda según la fecha
Q_net = 30000*ones(1,size(tiempo,2));
date_ini = tiempo(1);
date_ini.Month = 7;
date_ini.Day = 1;
date_end=  tiempo(1);
date_end.Month = 10;
date_end.Day = 1;
Q_net(and(tiempo>=date_ini,tiempo<date_end)) = 1;
date_ini = tiempo(1);
date_ini.Month = 5;
date_ini.Day = 1;
date_end=  tiempo(1);
date_end.Month = 7;
date_end.Day = 1;
hour_ini = hours(date_ini-tiempo(1));
hour_end = hours(date_end-tiempo(1));
HoY = hour_ini:1:hour_end-1;
Q_net(and(tiempo>=date_ini,tiempo<date_end)) = -30000/size(HoY,2)*(HoY-HoY(1))+30000;



clearvars curva
%% Eliminar variables, formar tablas y combinar vértices
edges = json2table(aristas,'properties');

nodes_coordinates = json2table(vertices,'geometry');
nodes = json2table(vertices,'properties');
for i = 1:size(nodes_coordinates.coordinates,1)
    nodes.x(i) = nodes_coordinates.coordinates{i}(1);
    nodes.y(i) = nodes_coordinates.coordinates{i}(2);
end


clearvars i pos val area nodes_coordinates


% % Comprobación grafo OK
% figure
% hold on
% for i = 1:size(edges,1)
%     plot([nodes.x(find(strcmp(nodes.num,edges.i(i))))...
%           nodes.x(find(strcmp(nodes.num,edges.j(i))))],...
%          [nodes.y(find(strcmp(nodes.num,edges.i(i))))...
%           nodes.y(find(strcmp(nodes.num,edges.j(i))))],'-k.')
%     pause(0.01)
% end

% A cada vértice se le asigna el área total de todas las conexiones cuyo
% identificador coincide (parcelas conectadas a ese vértice)

[val,pos]=intersect(nodes.id_conector,conexiones.id_conector);

%pos contiene la posición del array de vertices para la conexión de cada
%parcela, que es el que no tiene valores repetidos

area = zeros(size(nodes,1),1);
for i = 1:length(pos)
    area(pos(i)) = sum(conexiones.area(...
        conexiones.id_conector == val(i)));
end

area = array2table(area);
nodes = [nodes area];
areas = nodes.area(nodes.isConnection)';

%% Preparación del grafo completo
%Grafo completo de la red de nodos y carreteras
Gfull = graph(edges.i,edges.j,edges.weight);

%se eliminan aristas repetidas (véase captura)
Gfull = simplify(Gfull,'min');

%se reordenan los nodos para dejar primero las conexiones (variables de
%decisión del problema), seguidos de las fuentes y las variables de interés
indexes = ismember(nodes.Properties.VariableNames, {'num','x','y'});
nodes_data = [nodes(nodes.isConnection,indexes);
    nodes(nodes.isSource,indexes)];

number_of_sources = 1;
number_of_connections = sum(nodes.isConnection);
clearvars area vertices val pos nodes edges indexes date* aristas i conexiones

%% Parámetros del modelo económico

VAN_param.p = 0.05; %precio calor vendido en €/kWh
VAN_param.c = 0.17; %coste electricidad para bombeo en €/kWh
VAN_param.n = 30; %años
VAN_param.i = 0.03; %tasa de descuento
VAN_param.a = -209; %parametros coste subestaciones
VAN_param.b = 33841; %parametros coste subestaciones
VAN_param.C_1 = 354; %fórmulas Person et al
VAN_param.C_2 = 4314; %fórmulas Person et al
eta = 0.7596; %para densidad de 0.5 MWh/m -> 1.8 GJ/m -> d_a minimo 0.0293


%% Problema de OPTIMIZACIÓN

if size(areas,2) < 14085
    % Población con parcelas seleccionadas incialmente (ninguna para 2 km)
    x0 = zeros(1,number_of_connections);

else
    % Población con parcelas seleccionadas incialmente (de resultados generados para 2 km)
    nodes_data_new = nodes_data;
    load('nodos_2km.mat','nodes_data','population','scores')
    nodes_data_old = nodes_data;
    nodes_data = nodes_data_new;
    population_old = population(scores<0,:); % filtrado de VAN > 0
    [~,index] = ismember(nodes_data_old(1:end-1,1),nodes_data(1:end-1,1));
    x0 = zeros(size(population_old,1),number_of_connections);
    x0(:,index) = population_old;
end

% Opciones de optimización:
options = optimoptions('ga','UseParallel',true);
options = optimoptions(options,'MaxStallGenerations',1000);
options = optimoptions(options,'PopulationSize',1000);
options = optimoptions(options,'InitialPopulationMatrix',x0);
options = optimoptions(options,'Display', 'diagnose');

% Restricciones lineales
A = Q_dem'*areas;
A = A(Q_dem'>0,:); %se eliminan las horas en las que no hay demanda
b = Q_net'*eta;
b = b(Q_dem'>0,:); %se eliminan las horas en las que no hay demanda

% Algoritmo genético GA
[x,fval,exitflag,output,population,scores] =...
    ga(@(x) cost_fun(x,Gfull,areas,...
    nodes_data,number_of_sources,Q_dem',VAN_param),...
    length(x0),[],[],[],[],...
    zeros(1,length(x0)),ones(1,length(x0)),...
    @(x) nonlcon(x,A,b),...
    1:length(x0),options);

%% Representación
[network_length,selected_edges] = MST_selected_nodes(x,Gfull,...
    nodes_data,number_of_sources);

vertices_wgs84 = loadjson('vertices_wgs84.json');
nodes_wgs84 = json2table(vertices_wgs84,'properties');
nodes_coordinates_wgs84 = json2table(vertices_wgs84,'geometry');

for i = 1:size(nodes_coordinates_wgs84.coordinates,1)
    nodes_wgs84.lat(i) = nodes_coordinates_wgs84.coordinates{i}(2);
    nodes_wgs84.lon(i) = nodes_coordinates_wgs84.coordinates{i}(1);
end

gx=geoaxes;
gx.Basemap = 'satellite';
geolimits([36.68 36.82],[-2.88 -2.62])
hold on

for i=1:length(selected_edges)
    geoplot([nodes_wgs84.lat(strcmp(nodes_wgs84.num,Gfull.Edges.EndNodes{selected_edges(i),1}))... %latitud origen
        nodes_wgs84.lat(strcmp(nodes_wgs84.num,Gfull.Edges.EndNodes{selected_edges(i),2}))],... %latitud destino
        [nodes_wgs84.lon(strcmp(nodes_wgs84.num,Gfull.Edges.EndNodes{selected_edges(i),1}))... %longitud origen
        nodes_wgs84.lon(strcmp(nodes_wgs84.num,Gfull.Edges.EndNodes{selected_edges(i),2}))],...
        'LineWidth',2,'Color','black') %longitud destino
end
time = toc;

figure, hold on, plot(tiempo,Q_net*eta,'r')
plot(tiempo,Q_dem'*areas*x','k')