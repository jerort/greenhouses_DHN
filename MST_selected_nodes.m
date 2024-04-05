function [network_length,selected_edges] = ...
    MST_selected_nodes(selected_nodes,Gfull,nodes_data,number_of_sources)

%conservar solo nodos conexión seleccionados y fuentes de calor
selected_nodes = ([selected_nodes ones(1,number_of_sources)] == 1);
nodes_to_keep = nodes_data.num(selected_nodes);

if sum(selected_nodes) < 2
    network_length = 0;
    selected_edges = [];
else
    if sum(selected_nodes) == 2
        source = nodes_to_keep(end);
        target = nodes_to_keep(end-1);
    else
        %se calculan en cada fila los puntos que forman triángulos
        DT = delaunay(nodes_data.x(selected_nodes),nodes_data.y(selected_nodes));
        source = nodes_to_keep([DT(:,1);DT(:,1);DT(:,2)]);
        target = nodes_to_keep([DT(:,2);DT(:,3);DT(:,3)]);
    end
    % tic
    % G_weights = zeros(length(source),1);
    % [source_unique,~,idx_source]=unique(findnode(Gfull,source));
    % [target_unique,~,idx_target]=unique(findnode(Gfull,target));
    % d=distances(Gfull,source_unique,target_unique);
    % % G_weights = diag(d(idx_source,idx_target)); %mucho más lento https://es.mathworks.com/help/matlab/ref/sub2ind.html
    % parfor i = 1: length(idx_source)
    %     G_weights(i) = d(idx_source(i),idx_target(i));
    % end
    % time=toc;
    %
    % tic
    G_weights = zeros(length(source),1);
    parfor i = 1: length(source)
        [~,weight] = shortestpath(Gfull,source{i},target{i});
        G_weights(i) = weight;         %más lento
    end
    % time2=toc;

    %Nuevo grafo con solo los nodos de interfaz(subestaciones)
    G = graph(source,target,G_weights);

    %Cálculo del MST para el grafo con los nodos elegidos
    T = minspantree(G,'Method','sparse');

    selected_edges = [];
    % Longitud de la red (quitando segmentos duplicados)
    % tic
    parfor i = 1:size(T.Edges,1)
        [~,~,edges] = shortestpath(Gfull,T.Edges.EndNodes{i,1},...
            T.Edges.EndNodes{i,2});
        selected_edges = union(selected_edges,edges);
    end
    % time3=toc;

    network_length = sum(Gfull.Edges.Weight(selected_edges));
    %     parcelas = T.Nodes; %otra forma de obtener los nodos elegidos

end



end