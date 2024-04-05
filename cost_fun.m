function [cost] = cost_fun(x,Gfull,areas,nodes_data,number_of_sources,Q_dem,VAN_param)
%cost_fun proporciona el coste de la red para el agoritmo encargado de
%la selección de vertices óptima para el enrutado de la red térmica

L = MST_selected_nodes(x,Gfull,nodes_data,number_of_sources); %largo red
if L == 0
    cost = 0;
else
    [VAN] = VAN_fun(Q_dem,areas,x,L,VAN_param); %VAN del proyecto
    cost = -VAN;    
end
end