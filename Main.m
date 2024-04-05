clear
clc
close all

tic
%% Cargar datos
aristas = loadjson('aristas.json');
vertices = loadjson('vertices.json');
conexiones = loadjson('conexiones.json');


%% Eliminar variables, formar tablas y combinar vértices
edges = json2table(aristas,'properties');
nodes = json2table(vertices,'properties');
conexiones = json2table(conexiones,'properties');

nodes_coordinates = json2table(vertices,'geometry');
for i = 1:size(nodes_coordinates.coordinates,1) 
    nodes.x(i) = nodes_coordinates.coordinates{i}(1);
    nodes.y(i) = nodes_coordinates.coordinates{i}(2);
end

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

clearvars i pos val area

%% Preparación del grafo completo
%Grafo completo de la red de nodos y carreteras
Gfull = graph(edges.i,edges.j,edges.weight); 

%se eliminan aristas repetidas (véase captura)
Gfull = simplify(Gfull,'min'); 

%se reordenan los nodos para dejar primero las conexiones (variables de
%decisión del problema), seguidos de las fuentes y las variables de interés
nodes_data = [nodes(nodes.isConnection,2) nodes(nodes.isConnection,8) nodes(nodes.isConnection,9);
              nodes(nodes.isSource,2) nodes(nodes.isSource,8) nodes(nodes.isSource,9)];

number_of_sources = 1;

scenario = 0;

%% Problema de OPTIMIZACIÓN
% Vector de conexiones a parcelas seleccionadas incialmente (ninguna)
x0 = zeros(1,sum(nodes.isConnection));

% Opciones de optimización:
size(gcp);
options = optimoptions('ga','UseParallel',true);
options = optimoptions(options,'Display', 'diagnose');

% Algoritmo genético GA
x = ga(@(x) cost_fun(x,Gfull,nodes.area(nodes.isConnection)',...
                    nodes_data,number_of_sources,scenario),...
    length(x0),[],[],[],[],...
    zeros(1,length(x0)),ones(1,length(x0)),[],1:length(x0),options);

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