clear
clc
close all

%Datos ADE https://ens.dk/sites/ens.dk/files/Analyser/technology_data_catalogue_for_individual_heating_installations.pdf
x1 = [18,400];
y1 = [2700,16000];

%Datos Cofely http://www.districlima.com/districlima/uploads/descargas/guias-tecnicas/2012_05%20Gu%C3%ADa%20integral%20de%20desarrollo%20de%20proyectos%20de%20redes%20de%20distrito%20de%20calor%20y%20fr%C3%ADo.pdf
%valores mínimo y máximo de la curva roja
x2 = [300,2000];
y2 = [22000,36000];

x = [x1,x2];
y = [y1,y2];
x_inv = y./x;

f=fitlm(x_inv,y);
n = f.Coefficients{1,1}; %intercept
m = f.Coefficients{2,1}; %slope

figure
FS=12;
MS=6;
set(gcf,'pos',[100 100 800 400]);

%% primera

subplot(1,2,1)
box
hold on
y_pred = m*x_inv+n; 
meanerror = mean(y-y_pred);

plot(y1./x1,y1,'b*','MarkerSize',MS)
plot(y2./x2,y2,'ko','MarkerSize',MS)
plot(x_inv,y_pred,'r','LineWidth',1.5)


set(gca,'fontsize',FS)
set(gca,'fontname','Arial')
ylabel('Coste (€)')
xlabel('Ratio coste/potencia de la subestación (€/kW)')
position=get(gca,'pos');
set(gca,'pos',[position(1)-0.02 position(2)+0.05 position(3) position(4)-0.2]);
ax=gca; ax.YAxis.Exponent = 3;


txt1=sprintf(strcat('$C_{sub}^j=',string(round(m,0)),...
                    '\\cdot\\frac{C_{sub}^j}{Q_{sub}^j}+',...
                    string(round(n,0)),'$'));
txt1=convertStringsToChars(txt1);    
yL=get(gca,'YLim'); 
xL=get(gca,'XLim');   
text((xL(1)+xL(2))/5,yL(2)/1.1,txt1,...
  'HorizontalAlignment','left',...
  'VerticalAlignment','top',...
  'BackgroundColor',[1 1 1],...
  'EdgeColor',[1 1 1],...
  'FontName','Times New Roman',...
  'Interpreter','latex',...
  'FontSize',FS+1);


% add legend
leg1 = legend('(Cofely - Grupo GDF Suez, 2012)','(Agencia Danesa de la Energía, 2016)','Curva de ajuste');
leg1.Location='north';
position = leg1.Position;
leg1.Position = [position(1)+0.02 position(2)+0.23 position(3) position(4)];
leg1.FontSize=FS;

%% segunda

subplot(1,2,2)
box
hold on
x_pred = linspace(0,2000,100);
y_pred = n*x_pred./(x_pred-m); 

plot(x1,y1,'b*','MarkerSize',MS)
plot(x2,y2,'ko','MarkerSize',MS)
plot(x_pred,y_pred,'r','LineWidth',1.5) 


set(gca,'fontsize',FS)
set(gca,'fontname','Arial')
ylabel('Coste (€)')
xlabel('Potencia de la subestación (kW)')
position=get(gca,'pos');
set(gca,'pos',[position(1)+0.02 position(2)+0.05 position(3) position(4)-0.2]);
ax=gca; ax.YAxis.Exponent = 3;


txt1=sprintf(strcat('$C_{sub}^j=',string(round(n,0)),...
                    '\\cdot\\frac{Q_{sub}^j}{Q_{sub}^j+',...
                    string(abs(round(m,0))),'}',...
                    '$'));
txt1=convertStringsToChars(txt1);    
yL=get(gca,'YLim'); 
xL=get(gca,'XLim');   
text((xL(1)+xL(2))/4,yL(2)/5,txt1,...
  'HorizontalAlignment','left',...
  'VerticalAlignment','top',...
  'BackgroundColor',[1 1 1],...
  'EdgeColor',[1 1 1],...
  'FontName','Times New Roman',...
  'Interpreter','latex',...
  'FontSize',FS+1);


RMSE = f.RMSE;
R2 = f.Rsquared.Ordinary;


y_pred = n*x./(x-m); 
meanerror = mean(y-y_pred);
RMSE = sqrt(mean((y-y_pred).^2));
R = corrcoef(y_pred,y);
R2 = R(1,2)^2;


txt2_1=sprintf(strcat("$$ME = ",string(round(meanerror,4)),'$ EUR'));
txt2_2=sprintf(strcat("$RMSE = ",string(round(RMSE,0)),'$ EUR'));
txt2_3=sprintf(strcat("$R^2 = ",strrep(string(round(R2,4)),'.',','),'$'));

txt2=[convertStringsToChars(txt2_1),char(10),...
      convertStringsToChars(txt2_2),char(10),...
      convertStringsToChars(txt2_3)];    

yL=get(gca,'YLim'); 
xL=get(gca,'XLim');   
text((xL(1)+xL(2))/4,yL(2)/0.75,...
   txt2,...
  'HorizontalAlignment','left',...
  'VerticalAlignment','top',...
  'BackgroundColor',[1 1 1],...
  'EdgeColor',[0 0 0],...
  'FontName','Times New Roman',...
  'Interpreter','latex',...
  'FontSize',FS+1);

