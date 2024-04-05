function Q_cli = GH_heat_demand(area,perim,GH_model,TMY)
% Parameters
G = TMY.G; %global radiation
alpha = GH_model.alpha;
alpha_s = GH_model.alpha_s;
tau = GH_model.tau;
T_e = TMY.T;
T_i = GH_model.T_setpoint;
v = TMY.VV;
R = GH_model.R; %renovaciones por minuto (solo infiltración)
p = TMY.Patm/101325;
HR_e = TMY.HR;
HR_i = GH_model.HR_setpoint;

e_c = GH_model.e_c;
lambda_c = GH_model.lambda_c;

% Geometry 
V = area*GH_model.height; %voumen interior
S_d = perim*GH_model.height+area; %superficie cubierta
S_c = area; %sup suelo

% Solar radiation
R_n = G.*alpha.*S_d+G.*tau.*alpha_s.*S_c;

% Convection-conduction 
h_e = 7.2 + 3.84.*v; % https://www.sciencedirect.com/science/article/pii/0021863487901144
h_i = 7.2;           % (Garzoli y Blackwell, 1987)
K_cc= 1./(1./h_i+e_c./lambda_c+1./h_e);
Q_cc = S_d.*K_cc.*(T_i-T_e);

% Air renovations
ro = 1000 .* p./(1.01287.*(T_i+273.15));
lambda_o = 2502535.259-2385.76424*T_i;
c_pa = 1006.92540;
c_pv = 1875.6864;

e_s = 6.1078 .* exp(17.269.*T_e./(T_e+237.3));
x_e = 0.6219.*HR_e.*e_s./(p.*HR_e.*e_s);

e_s = 6.1078 .* exp(17.269.*T_i./(T_i+237.3));
x_i = 0.6219.*HR_i.*e_s./(p.*HR_i.*e_s);

Q_ren = V .* R./3600 .* ro .* [c_pa.*(T_i-T_e) + ...
                               lambda_o.*(x_i-x_e) +...                               
                               c_pv.*(x_i.*(T_i+273.15)-x_e.*(T_e+273.15))];

% Latent heat
Q_evp = 0;

% Soil heat loss
Q_sue = (Q_cc+Q_ren)/0.9*0.1;

% Heat demand
Q_cli = Q_cc+Q_ren+Q_evp+Q_sue-R_n;

end