function [VAN,Q_sub,C_sub,d_a,E,L,C_inv,C_op] = VAN_fun(Q_dem,areas,x,L,VAN_param)

p = VAN_param.p; %precio calor vendido en €/kWh
c = VAN_param.c; %coste electricidad para bombeo en €/kWh
n = VAN_param.n; %años
i = VAN_param.i; %tasa de descuento
a = VAN_param.a; %parametros coste subestaciones
b = VAN_param.b; %parametros coste subestaciones
C_1 = VAN_param.C_1; %fórmulas Person et al
C_2 = VAN_param.C_2; %fórmulas Person et al

E = sum(Q_dem)*sum(x.*areas); %demanda de calor en kWh
if (E/1000)/L < 0.5
    VAN = -1000000;
    Q_sub =[];
    C_sub = 0;
    d_a = 0;
    E = 0;    
    C_inv = 0;
    C_op = 0;
else
    %subestaciones
    Q_sub = max(Q_dem)*areas*diag(x);
    Q_sub(Q_sub <= 0) = 0;
    C_sub = sum(b*Q_sub(Q_sub>0)./(Q_sub(Q_sub>0)-a));
    %fórmulas persson et al
    d_a = 0.0486*log((E*3.6/1000)/L)+0.0007; %el calor se pasa a MWh en esta fórmula

    %Costes inversión
    C_inv = L*(C_1+C_2*d_a)+C_sub; %€/kWh

    %Costes operación
    eta_net = 1-0.17*((E/1000)/L)^(-0.5);
    C_op = 0.01/eta_net*E*c;

    %VAN
    flow  = 0;
    for j=1:n
        flow = flow + (p*E-C_op)/(1+i)^j;
    end
    VAN = -C_inv + flow;    
end
end