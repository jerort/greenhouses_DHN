clear
clc
close all

%% Cargar datos
conexiones = loadjson('conexiones_wgs84.json');


%% Eliminar variables y formar tablas
conexiones_coordinates = json2table(conexiones,'geometry');
conexiones = json2table(conexiones,'properties');

for i = 1:size(conexiones_coordinates.coordinates,1) 
    conexiones.x(i) = conexiones_coordinates.coordinates{i}(1);
    conexiones.y(i) = conexiones_coordinates.coordinates{i}(2);
end


%% Modelos
% amplitud resolucioón espacial PVGIS 0.28º
amplitud_centroides = [abs(max(conexiones.y)-min(conexiones.y)) abs(max(conexiones.x)-min(conexiones.x))]; %latitud - longitud
% Se toma el centroide de la planta para el TMY
% TMY = API_PVGIS_TMY(36.731536491760913,-2.774636978552545);
load('TMY.mat')

dia = TMY.G>0;
noche = TMY.G<=0;

T = 10 * noche + 22 * dia;

% Modelo invernadero *Coextrusión PE-EVA-PE valores más restrictivos IDAE
GH_model = struct('height',2.5,...
                  'lambda_c',0.33,... *más restrictivo que el 0.45 de la eva
                  'e_c',0.2,...
                  'alpha',0.04,...
                  'alpha_s',0.18,...
                  'tau',0.89,...
                  'R',2,...
                  'T_setpoint',T,...
                  'HR_setpoint',60);

% Cálculo potencia demandada
parfor i = 1:size(conexiones_coordinates.coordinates,1)    
    Q = GH_heat_demand(conexiones.area(i),conexiones.perimetro(i),GH_model,TMY);
    Qref(i,:) = Q;    
    Qcal(i,:) = Q;
end
Qref(Qref>0) = 0;
Qcal(Qcal<0) = 0;
% conexiones.Q_ref = Qref/1000; %kW
conexiones.Q_cal = Qcal/1000; %kW
% conexiones.Q_den_ref = sum(Qref,2)./conexiones.area/1e9*1e6; %GWh/km^2
conexiones.Q_den_cal = sum(Qcal,2)./conexiones.area/1e9*1e6; %GWh/km^2

clearvars -except conexiones

%% Representación
FS = 10
figure('pos',[100 100 600 300])
histogram(conexiones.Q_den_cal*3.6) %MJ/m^2
hold on
plot([mean(conexiones.Q_den_cal*3.6) mean(conexiones.Q_den_cal*3.6)],[0 1400])
set(gca,'fontsize',FS)
legend('Parcelas identificadas','Valor medio')
xlabel('Densidad energética anual (MJ/m^2)','FontSize', FS,'FontName','Arial')
ylabel('Número de parcelas','FontSize', FS,'FontName','Arial')
max(conexiones.Q_den_cal*3.6)
mean(conexiones.Q_den_cal*3.6)
min(conexiones.Q_den_cal*3.6)

tiempo = datetime(2023,1,1,0,0,0):hours(1):datetime(2023,12,31,23,0,0);
curva = mean(conexiones.Q_cal./conexiones.area,1);
figure('pos',[100 100 600 300])
plot(tiempo,curva) %kW/m^2
set(gca,'fontsize',FS)
xaxis=get(gca,'xaxis');
xaxis.TickLabels={'Ene',...
                  'Feb',...
                  'Mar',...
                  'Abr',...
                  'May',...
                  'Jun',...
                  'Jul',...
                  'Ago',...
                  'Sep',...
                  'Oct',...
                  'Nov',...
                  'Dic',...
                  'Ene'};
xlabel('Mes','FontSize', FS,'FontName','Arial')
ylabel('Demanda térmica (kW/m^2)','FontSize', FS,'FontName','Arial')