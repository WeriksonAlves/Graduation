%% Trabalho 1: Werikson ELT472
% #########################################################################
%%%% Pioneer P3-Dx: Controle de posição sem orientação final %%%%
% #########################################################################

clc, clear  
close all

% Close all the open connections
try
    fclose(instrfindall);
catch
end

%% Solução para encontrar qualquer AuRoRa

% Procura o diretorio com todos os arquivos relacionados ao projeto
% Procura o diretorio com todos os arquivos relacionados ao projeto
PastaAtual = pwd;
PastaRaiz = 'ELT472';
cd(PastaAtual(1:(strfind(PastaAtual,PastaRaiz)+numel(PastaRaiz)-1)))
addpath(genpath(pwd))

%% Classes initialization - Definindo o Robô
% Criando uma variável para representar o Robô

tic
P = Pioneer3DX;
toc 

%P.pPar.a = 0;
%P.pPar.alpha = 0*pi/3;

% Tempo de esperar para início do experimento/simulação
% clc;
fprintf('\nInício..............\n\n')
pause(1)

%% Definindo a Figura que irá rodar a simulação
% P.mPlotInit;
f1 = figure('Name','Simulação: Robótica Móvel (Pioneer P3-Dx)','NumberTitle','off');
% f1.Position = [435 2 930 682];
f1.Position = [1 2 930 682];
figure(f1);

ax = gca;
ax.FontSize = 12;
xlabel({'$$x$$ [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
ylabel({'$$y$$ [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
zlabel({'$$z$$ [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
axis equal
view(3)
view(0,90)
grid on
hold on
grid minor
light;
axis([-5 5 -5 5 0 2])
set(gca,'Box','on');

%% P.mCADplot();
t = tic;
P.mCADplot;
drawnow

disp([num2str(toc(t)) 's para 1º plot'])

P.mCADcolor([0.5 0.5 0.5]);

pause()

%% Initial Position
% Xo = input('Digite a posição inicial do robô ([x y z psi]): ');
Xo = [0 0 0 0];

P.rSetPose(Xo);         % define pose do robô

%% Variables initialization
% Xa = P.pPos.X(1:6);    % postura anterior
data = [];
Rastro.Xd = [];
Rastro.X = [];

% Temporização
T = 90;      % Periodo de cada volta da elipse
tsim = 2*T;  % Tempo total da simulação
tap = 0.100; % taxa de atualização do pioneer

%% Simulation

% Parâmetros de controle
gains.umax = 1;%0.35;
gains.wmax = 1;%0.44;

% Parâmetros da trajetória
w = (2*pi/T);
Rx = 2.5; %[m]
Ry = 1.5; %[m]

% Parâmetros de desempenho
IAE = 0;
ITAE = 0;
IASC = 0;

% Simulação em tempo de máquina
for t = 0:tap:tsim
    % Data aquisition
    P.rGetSensorData;
    
    % Trajetoria Eliptica:
    P.pPos.Xd(1:2) = [Rx*cos(w*t); Ry*sin(w*t)];
    P.pPos.Xd(7:8) = [-Rx*w*sin(w*t); Ry*w*cos(w*t)];
    
    % -----------------------------------------------------
    %P = Controladores(P,gains);
    %P = Ctrl_tgh(P,gains,1,0.41);
    %P = Ctrl_inv(P,gains,1,0.41,0.17,0.01);
    P = Ctrl_exp(P,gains,2,0.06);
    %P = Ctrl_gau(P,gains,1,0.41,0.04,2);
    %P = Ctrl_sqrt(P,gains,0.98,2);
    
    % -----------------------------------------------------
    
    % Enviar sinais de controle para o robô
    P.rSendControlSignals;
    if t>T
        ITAE = t*norm(P.pPos.Xtil(1:2))*tap;
        IAE = 0;
        IASC = 0;
    else
        IASC = norm(P.pSC.Ud(1:2))*tap;
        IAE = norm(P.pPos.Xtil(1:2))*tap;
        ITAE = 0;
    end

    % Verifica a saturação
    if (P.pSC.Ud(1)>0.75) || (P.pSC.Ud(2)>1.74)
        disp(['Saturado: ' num2str(P.pSC.Ud(1)) ' e ' num2str(P.pSC.Ud(2))])
        break
    end
    
    % salva variáveis para plotar no gráfico
    Rastro.Xd = [Rastro.Xd; P.pPos.Xd(1:2)'];  % formação desejada
    Rastro.X  = [Rastro.X; P.pPos.X(1:2)'];    % formação real
    
    data = [data; P.pPos.Xd' P.pPos.X' P.pSC.Ud' P.pSC.U' P.pPos.rho P.pPos.alpha P.pPos.theta IAE ITAE IASC t];
    
    % --------------------------------------------------------------- %
    
    %% Desenha o robô
    try
        delete(h);
        P.mCADdel;
    end
    hold on
    P.mCADplot;
    h(1) = plot(Rastro.Xd(:,1),Rastro.Xd(:,2),'xk','MarkerSize',8.5,'LineWidth',1);
    h(2) = plot(Rastro.X(:,1),Rastro.X(:,2),'g','LineWidth',1);
    axis([-5 5 -5 5])
    grid on
    hold off
    drawnow        
end
if t == 180
    teste = [mean(data(:,32)), mean(data(:,33)), mean(data(:,34));
             sum(data(:,32),1),sum(data(:,33),1),sum(data(:,34),1)]
end
save("Trabalhos\T1\Simulação\SAVE\data","data")
%%  Stop robot
% Zera velocidades do robô
P.pSC.Ud = [0 ; 0];
%P.rSendControlSignals;
% End of code xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
pause(2)

%% Figuras
% Rota descrita pelo robô:
legend([h(1) h(2)],{'$\textbf{x}_d$','$\textbf{x}$'},'FontSize',20,'interpreter','latex','Position',[0.82 0.52 0.084 0.10])
saveas(gcf,"Trabalhos\T1\Simulação\SAVE\Fig_1.png")
%% Sinais de Controle (Fazer um lado do eixo y com velocidade linear e o outro com angular)
figure();
ax = gca;
ax.FontSize = 12;
yyaxis left
plot(data(:,end),data(:,25),'--k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
ylabel({'Velocidade Linear [m/s]'},'FontSize',16,'FontWeight','bold','interpreter','latex');
yyaxis right 
plot(data(:,end),data(:,26),'-.b','LineWidth',1.5);
ylabel({'Velocidade Angular [rad/s]'},'FontSize',16,'FontWeight','bold','interpreter','latex');
xlabel({'$$t_{simu}$$ [s]'},'FontSize',16,'FontWeight','bold','interpreter','latex');

legend({'$u$','$\omega$'},'FontSize',18,'interpreter','latex','location','south')

hAx = gca;                       
set(hAx.YAxis,{'Color'},{'k'})   
grid on
axis equal
axis tight
saveas(gcf,"Trabalhos\T1\Simulação\SAVE\Fig_2.png")
%% Erros de posição:
figure();
plot(data(:,end),(data(:,1)-data(:,13)),'--k',data(:,end),(data(:,2)-data(:,14)),'-.k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
xlabel({'$$t_{simu}$$ [s]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
ylabel({'Erro de Posi\c{c}{\~a}o [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
legend({'$\tilde{x}$','$\tilde{y}$'},'FontSize',20,'interpreter','latex','Position',[0.83 0.87 0.091 0.092])
grid on
axis tight
saveas(gcf,"Trabalhos\T1\Simulação\SAVE\Fig_3.png")
%%         
%data = [data; P.pPos.Xd' P.pPos.X' P.pSC.Ud' P.pSC.U' toc(t)];
            %  (1:12)    (13:24)    (25:26)   (27:28)
%% Erros de orientação:
figure();
plot(data(:,end),(data(:,6)-data(:,18)),'-k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
xlabel({'$$t_{simu}$$ [s]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
ylabel({'Erro de Orienta\c{c}{\~a}o [rad]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
legend({'$\tilde{\beta}$'},'FontSize',20,'interpreter','latex','box','off')
grid on
axis tight
saveas(gcf,"Trabalhos\T1\Simulação\SAVE\Fig_4.png")
%% Gráfico para Rho e alpha:

figure();
subplot(311,'Position',[0.128214285714286 0.670693274231353 0.775 0.229306725768648])
plot(data(:,end),data(:,29),'-k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
xticklabels({})
ylabel({'$$\rho$$ [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
grid on
axis tight

subplot(312,'Position',[0.13 0.407142857142857 0.775 0.242857142857143])
plot(data(:,end),data(:,30),'-.k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
xticklabels({})
ylabel({'$$\alpha$$ [rad]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
grid on
axis tight

subplot(313,'Position',[0.128214285714286 0.154761904761905 0.775 0.232878151260504])
plot(data(:,end),data(:,31),'--k','LineWidth',1.5);
ax = gca;
ax.FontSize = 12;
xlabel({'$$t_{simu}$$ [s]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
ylabel({'$$\beta$$ [m]'},'FontSize',18,'FontWeight','bold','interpreter','latex');
grid on
axis tight
saveas(gcf,"Trabalhos\T1\Simulação\SAVE\Fig_5.png")