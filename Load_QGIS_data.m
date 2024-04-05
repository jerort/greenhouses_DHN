%% Cargar datos
aristas = loadjson('aristas.json');
vertices = loadjson('vertices.json');
conexiones = loadjson('conexiones_wgs84.json');


%% Eliminar variables, formar tablas y combinar vértices
edges = json2table(aristas,'properties');

nodes_coordinates = json2table(vertices,'geometry');
nodes = json2table(vertices,'properties');
for i = 1:size(nodes_coordinates.coordinates,1) 
    nodes.x(i) = nodes_coordinates.coordinates{i}(1);
    nodes.y(i) = nodes_coordinates.coordinates{i}(2);
end

conexiones_coordinates = json2table(conexiones,'geometry');
conexiones = json2table(conexiones,'properties');
for i = 1:size(conexiones_coordinates.coordinates,1) 
    conexiones.x(i) = conexiones_coordinates.coordinates{i}(1);
    conexiones.y(i) = conexiones_coordinates.coordinates{i}(2);
end

clearvars i pos val area nodes_coordinates conexiones_coordinates