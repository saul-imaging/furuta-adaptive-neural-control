clc
close all
format longE

%% ============================================================
%  Configuracion para figuras de paper
%  ============================================================
EXPORT_FIGS = false;        % Cambia a true si quieres guardar PDF vectoriales
OUT_DIR     = 'figures_paper';

if EXPORT_FIGS && ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR)
end

FS_AXES   = 16;
FS_LABEL  = 18;
FS_TITLE  = 20;
FS_LEGEND = 14;
LW        = 2.2;

set(groot,'defaultAxesFontSize',FS_AXES)
set(groot,'defaultTextFontSize',FS_LABEL)
set(groot,'defaultLegendFontSize',FS_LEGEND)
set(groot,'defaultLineLineWidth',LW)
set(groot,'defaultFigureColor','w')

%% ============================================================
%  Extraer senales principales
%  ============================================================
th0_LQR_ts = out.get('Th0_LQR');
th1_LQR_ts = out.get('Th1_LQR');

th0_NN_ts  = out.get('Th0_ANC');
th1_NN_ts  = out.get('Th1_ANC');

th0_ref_ts = out.get('th0_ref');
th1_ref_ts = out.get('th1_ref');

tau_LQR_ts = out.get('Tau_LQR');
tau_NN_ts  = out.get('Tau_ANC');

%% Senales neuronales opcionales
% W_bias debe venir como mux: [W1 W2 W3 W4 bias]
% Si alguna senal no existe en el Workspace, el codigo no truena.
normW_ts  = getSignalIfExists(out, 'normW');
W_bias_ts = getSignalIfExists(out, 'W_bias');
Xnn_ts    = getSignalIfExists(out, 'Xnn');
z_ts      = getSignalIfExists(out, 'z');
eNN_ts    = getSignalIfExists(out, 'eNN');

%% ============================================================
%  Tiempo base
%  ============================================================
t = th0_ref_ts.Time(:);
tw = t - t(1);

%% ============================================================
%  Extraer datos principales
%  ============================================================
th0_ref = getData(th0_ref_ts, t); th0_ref = th0_ref(:,1);
th1_ref = getData(th1_ref_ts, t); th1_ref = th1_ref(:,1);

th0_LQR = getData(th0_LQR_ts, t); th0_LQR = th0_LQR(:,1);
th1_LQR = getData(th1_LQR_ts, t); th1_LQR = th1_LQR(:,1);

th0_NN = getData(th0_NN_ts, t); th0_NN = th0_NN(:,1);
th1_NN = getData(th1_NN_ts, t); th1_NN = th1_NN(:,1);

tau_LQR = getData(tau_LQR_ts, t); tau_LQR = tau_LQR(:,1);
tau_NN  = getData(tau_NN_ts, t);  tau_NN  = tau_NN(:,1);

%% ============================================================
%  Extraer datos neuronales opcionales
%  ============================================================
normW  = [];
W_bias = [];
W_NN   = [];
b_NN   = [];
Xnn    = [];
z      = [];
eNN    = [];

if ~isempty(normW_ts)
    normW = getData(normW_ts, t);
    normW = normW(:,1);
end

if ~isempty(W_bias_ts)
    W_bias = getData(W_bias_ts, t);
    [W_NN, b_NN] = splitWeightsBias(W_bias);
end

if isempty(normW) && ~isempty(W_NN)
    normW = sqrt(sum(W_NN.^2, 2));
end

if ~isempty(Xnn_ts)
    Xnn = getData(Xnn_ts, t);
end

if ~isempty(z_ts)
    z = getData(z_ts, t);
    z = z(:,1);
end

if ~isempty(eNN_ts)
    eNN = getData(eNN_ts, t);
    eNN = eNN(:,1);
end

%% ============================================================
%  Errores angulares
%  ============================================================
e0_LQR = atan2(sin(th0_LQR - th0_ref), cos(th0_LQR - th0_ref));
e1_LQR = atan2(sin(th1_LQR - th1_ref), cos(th1_LQR - th1_ref));

e0_NN = atan2(sin(th0_NN - th0_ref), cos(th0_NN - th0_ref));
e1_NN = atan2(sin(th1_NN - th1_ref), cos(th1_NN - th1_ref));

e_norm_LQR = sqrt(e0_LQR.^2 + e1_LQR.^2);
e_norm_NN  = sqrt(e0_NN.^2  + e1_NN.^2);

%% ============================================================
%  Metricas de seguimiento
%  ============================================================
ITSE_LQR_th0 = trapz(t, tw .* e0_LQR.^2);
ITSE_LQR_th1 = trapz(t, tw .* e1_LQR.^2);

ITSE_NN_th0 = trapz(t, tw .* e0_NN.^2);
ITSE_NN_th1 = trapz(t, tw .* e1_NN.^2);

q0 = 1;
q1 = 10;

ITSE_total_LQR = trapz(t, tw .* (q0*e0_LQR.^2 + q1*e1_LQR.^2));
ITSE_total_NN  = trapz(t, tw .* (q0*e0_NN.^2  + q1*e1_NN.^2));

RMSE_th0_LQR = rms(e0_LQR);
RMSE_th1_LQR = rms(e1_LQR);
RMSE_th0_NN  = rms(e0_NN);
RMSE_th1_NN  = rms(e1_NN);

MaxE_th0_LQR = max(abs(e0_LQR));
MaxE_th1_LQR = max(abs(e1_LQR));
MaxE_th0_NN  = max(abs(e0_NN));
MaxE_th1_NN  = max(abs(e1_NN));

%% ============================================================
%  Metricas de torque
%  ============================================================
ISE_tau_LQR  = trapz(t, tau_LQR.^2);
ISE_tau_NN   = trapz(t, tau_NN.^2);

ITSE_tau_LQR = trapz(t, tw .* tau_LQR.^2);
ITSE_tau_NN  = trapz(t, tw .* tau_NN.^2);

Tau_RMS_LQR = rms(tau_LQR);
Tau_RMS_NN  = rms(tau_NN);

Tau_Max_LQR = max(abs(tau_LQR));
Tau_Max_NN  = max(abs(tau_NN));

%% ============================================================
%  Tablas para el paper
%  ============================================================
Tabla_Tracking = table( ...
    ["LQR"; "Neural"], ...
    [RMSE_th0_LQR; RMSE_th0_NN], ...
    [RMSE_th1_LQR; RMSE_th1_NN], ...
    [MaxE_th0_LQR; MaxE_th0_NN], ...
    [MaxE_th1_LQR; MaxE_th1_NN], ...
    [ITSE_LQR_th0; ITSE_NN_th0], ...
    [ITSE_LQR_th1; ITSE_NN_th1], ...
    [ITSE_total_LQR; ITSE_total_NN], ...
    'VariableNames', {'Controller','RMSE_theta0','RMSE_theta1', ...
    'MaxAbsError_theta0','MaxAbsError_theta1','ITSE_theta0','ITSE_theta1','Weighted_ITSE'} ...
);

Tabla_Torque = table( ...
    ["LQR"; "Neural"], ...
    [ISE_tau_LQR; ISE_tau_NN], ...
    [ITSE_tau_LQR; ITSE_tau_NN], ...
    [Tau_RMS_LQR; Tau_RMS_NN], ...
    [Tau_Max_LQR; Tau_Max_NN], ...
    'VariableNames', {'Controller','ISE_tau','ITSE_tau','Tau_RMS','Tau_Max'} ...
);

disp("============================================")
disp("Tracking performance metrics")
disp("============================================")
disp(Tabla_Tracking)

disp("============================================")
disp("Control effort metrics")
disp("============================================")
disp(Tabla_Torque)

%% ============================================================
%  Guardar tablas en CSV
%  ============================================================

SAVE_TABLES = true;
TABLE_DIR = fullfile(pwd, 'results', 'generated_tables');

if SAVE_TABLES && ~exist(TABLE_DIR, 'dir')
    mkdir(TABLE_DIR)
end

if SAVE_TABLES
    writetable(Tabla_Tracking, fullfile(TABLE_DIR, 'tracking_metrics.csv'))
    writetable(Tabla_Torque,   fullfile(TABLE_DIR, 'control_effort_metrics.csv'))

    disp("============================================")
    disp("CSV files saved in folder: " + TABLE_DIR)
    disp("============================================")
end

%% ============================================================
%  Figura 1: Seguimiento de theta0 y theta1
%  ============================================================
fig1 = figure('Name','Tracking comparison','Units','normalized','Position',[0.05 0.10 0.85 0.75]);
tiledlayout(2,1,'TileSpacing','compact','Padding','compact')

nexttile
plot(t, th0_ref, 'k--', 'LineWidth', LW)
hold on
plot(t, th0_LQR, 'LineWidth', LW)
plot(t, th0_NN,  'LineWidth', LW)
formatAxes(FS_AXES)

ylabel('theta_0 [rad]', 'FontSize', 22)
title('theta_0 tracking performance', 'FontSize', FS_TITLE)

legend('theta_0 ref', 'LQR', 'Neural', ...
    'Location', 'southeast', ...
    'FontSize', 18)

nexttile
plot(t, th1_ref, 'k--', 'LineWidth', LW)
hold on
plot(t, th1_LQR, 'LineWidth', LW)
plot(t, th1_NN,  'LineWidth', LW)
formatAxes(FS_AXES)

xlabel('Time [s]', 'FontSize', 22)
ylabel('theta_1 [rad]', 'FontSize', 22)
title('theta_1 tracking performance', 'FontSize', FS_TITLE)

legend('theta_1 ref', 'LQR', 'Neural', ...
    'Location', 'southeast', ...
    'FontSize', 18)

savePaperFig(fig1, OUT_DIR, 'fig01_tracking_comparison.pdf', EXPORT_FIGS)

% %% ============================================================
% %  Figura 2: Error de seguimiento de theta0
% %  ============================================================
% fig2 = figure('Name','Theta0 tracking error','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
% plot(t, e0_LQR, 'LineWidth', LW)
% hold on
% plot(t, e0_NN, 'LineWidth', LW)
% 
% formatAxes(FS_AXES)
% xlabel('Time [s]', 'FontSize', FS_LABEL)
% ylabel('e_{\theta_0} [rad]', 'FontSize', FS_LABEL)
% title('\theta_0 tracking error', 'FontSize', FS_TITLE)
% legend('LQR', 'Neural', 'Location', 'best', 'FontSize', FS_LEGEND)
% 
% savePaperFig(fig2, OUT_DIR, 'fig02_theta0_tracking_error.pdf', EXPORT_FIGS)
% 
% %% ============================================================
% %  Figura 3: Error de seguimiento de theta1
% %  ============================================================
% fig3 = figure('Name','Theta1 tracking error','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
% plot(t, e1_LQR, 'LineWidth', LW)
% hold on
% plot(t, e1_NN, 'LineWidth', LW)
% 
% formatAxes(FS_AXES)
% xlabel('Time [s]', 'FontSize', FS_LABEL)
% ylabel('e_{\theta_1} [rad]', 'FontSize', FS_LABEL)
% title('\theta_1 tracking error', 'FontSize', FS_TITLE)
% legend('LQR', 'Neural', 'Location', 'best', 'FontSize', FS_LEGEND)
% 
% savePaperFig(fig3, OUT_DIR, 'fig03_theta1_tracking_error.pdf', EXPORT_FIGS)
% 
% %% ============================================================
% %  Figura 4: Norma del error total
% %  ============================================================
% fig4 = figure('Name','Total tracking error norm','Units','normalized','Position',[0.08 0.15 0.80 0.55]);
% 
% plot(t, e_norm_LQR, 'LineWidth', LW)
% hold on
% plot(t, e_norm_NN, 'LineWidth', LW)
% 
% formatAxes(FS_AXES)
% xlabel('Time [s]', 'FontSize', FS_LABEL)
% ylabel('||e(t)|| [rad]', 'FontSize', FS_LABEL)
% title('Total tracking error norm', 'FontSize', FS_TITLE)
% legend('LQR', 'Neural', 'Location', 'best', 'FontSize', FS_LEGEND)
% 
% savePaperFig(fig4, OUT_DIR, 'fig04_tracking_error_norm.pdf', EXPORT_FIGS)
% 
% %% ============================================================
% %  Figura 5: Torque aplicado
% %  ============================================================
% fig5 = figure('Name','Applied control torque','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
% plot(t, tau_LQR, 'LineWidth', LW)
% hold on
% plot(t, tau_NN, 'LineWidth', LW)
% 
% formatAxes(FS_AXES)
% xlabel('Time [s]', 'FontSize', FS_LABEL)
% ylabel('\tau [N m]', 'FontSize', FS_LABEL)
% title('Applied control torque', 'FontSize', FS_TITLE)
% legend('LQR', 'Neural', 'Location', 'best', 'FontSize', FS_LEGEND)
% 
% ylim([-0.07 0.04])
% 
% savePaperFig(fig5, OUT_DIR, 'fig05_applied_control_torque.pdf', EXPORT_FIGS)
% 
% %% ============================================================
% %  Figura 6: Pesos neuronales y bias
% %  ============================================================
% if ~isempty(W_bias)
%     fig6 = figure('Name','Neural weights and bias','Units','normalized','Position',[0.08 0.12 0.80 0.60]);
% 
%     plotMatrixSignals(t, W_bias, LW)
% 
%     formatAxes(FS_AXES)
%     xlabel('Time [s]', 'FontSize', FS_LABEL)
%     ylabel('Parameter value', 'FontSize', FS_LABEL)
%     title('Neural weights and bias evolution', 'FontSize', FS_TITLE)
% 
%     if size(W_bias,2) >= 5
%         legendLabels = [makeLegend('W', size(W_bias,2)-1), "bias"];
%     else
%         legendLabels = makeLegend('p', size(W_bias,2));
%     end
% 
%     legend(legendLabels, 'Location', 'best', 'FontSize', FS_LEGEND)
% 
%     savePaperFig(fig6, OUT_DIR, 'fig06_weights_bias.pdf', EXPORT_FIGS)
% end
% 
% %% ============================================================
% %  Figura 6 opcional: Entradas neuronales Xnn
% %  ============================================================
% % Esta figura es mas de diagnostico que de paper. Si la quieres ver,
% % cambia PLOT_XNN a true.
% 
% PLOT_XNN = false;
% 
% if PLOT_XNN && ~isempty(Xnn)
%     fig6 = figure('Name','Neural input vector Xnn','Units','normalized','Position',[0.06 0.05 0.85 0.85]);
%     plotMatrixSignals(t, Xnn, LW)
%     formatAxes(FS_AXES)
%     xlabel('Time [s]', 'FontSize', FS_LABEL)
%     ylabel('Xnn_i', 'FontSize', FS_LABEL)
%     title('Neural input vector components', 'FontSize', FS_TITLE)
%     legend(makeLegend('Xnn', size(Xnn,2)), 'Location', 'best', 'FontSize', FS_LEGEND)
% 
%     savePaperFig(fig6, OUT_DIR, 'fig06_xnn_components.pdf', EXPORT_FIGS)
% end
% %% ============================================================
% %  Figura 7: Norma de los pesos
% %  ============================================================
% if ~isempty(normW)
%     fig7 = figure('Name','Neural weight norm','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
%     plot(t, normW, 'LineWidth', LW)
% 
%     formatAxes(FS_AXES)
%     xlabel('Time [s]', 'FontSize', FS_LABEL)
%     ylabel('||W||', 'FontSize', FS_LABEL)
%     title('Neural weight norm', 'FontSize', FS_TITLE)
% 
%     savePaperFig(fig7, OUT_DIR, 'fig07_weight_norm.pdf', EXPORT_FIGS)
% end
% 
% %% ============================================================
% %  Figura 8: Error neuronal de aprendizaje
% %  ============================================================
% if ~isempty(eNN)
%     fig8 = figure('Name','Neural learning error','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
%     plot(t, eNN, 'LineWidth', LW)
% 
%     formatAxes(FS_AXES)
%     xlabel('Time [s]', 'FontSize', FS_LABEL)
%     ylabel('e_{NN}', 'FontSize', FS_LABEL)
%     title('Neural learning error', 'FontSize', FS_TITLE)
% 
%     savePaperFig(fig8, OUT_DIR, 'fig08_neural_learning_error.pdf', EXPORT_FIGS)
% end
% 
% %% ============================================================
% %  Figura 9: Argumento de activacion neuronal
% %  ============================================================
% if ~isempty(z)
%     fig9 = figure('Name','Neural activation argument','Units','normalized','Position',[0.10 0.15 0.75 0.55]);
% 
%     plot(t, z, 'LineWidth', LW)
% 
%     formatAxes(FS_AXES)
%     xlabel('Time [s]', 'FontSize', FS_LABEL)
%     ylabel('z', 'FontSize', FS_LABEL)
%     title('Neural activation argument', 'FontSize', FS_TITLE)
% 
%     savePaperFig(fig9, OUT_DIR, 'fig09_neural_activation_argument.pdf', EXPORT_FIGS)
% end
%% ============================================================
%  Funciones locales
%  ============================================================
function ts = getSignalIfExists(simout, signalName)
    ts = [];
    try
        tmp = simout.get(signalName);
        if ~isempty(tmp)
            ts = tmp;
        end
    catch
        ts = [];
    end
end

function y = getData(ts, tbase)
    t_sig = ts.Time(:);
    data  = ts.Data;

    y = timeseriesDataToMatrix(data, numel(t_sig));

    if size(y,1) == 1 && numel(tbase) > 1
        y = repmat(y, numel(tbase), 1);
        return
    end

    if size(y,1) ~= numel(tbase)
        y = interp1(t_sig, y, tbase, 'linear', 'extrap');
    else
        if numel(t_sig) == numel(tbase)
            if max(abs(t_sig - tbase)) > 1e-12
                y = interp1(t_sig, y, tbase, 'linear', 'extrap');
            end
        end
    end
end

function y = timeseriesDataToMatrix(data, nT)
    data = squeeze(data);

    if isscalar(data)
        y = data;
        return
    end

    if isvector(data)
        if numel(data) == nT
            y = data(:);
        else
            y = reshape(data, 1, []);
        end
        return
    end

    sz = size(data);
    idxTime = find(sz == nT, 1, 'last');

    if isempty(idxTime)
        y = reshape(data, size(data,1), []);
    else
        order = [idxTime, setdiff(1:ndims(data), idxTime, 'stable')];
        dataPerm = permute(data, order);
        y = reshape(dataPerm, nT, []);
    end
end

function [W_NN, b_NN] = splitWeightsBias(W_bias)
    W_NN = [];
    b_NN = [];

    if isempty(W_bias)
        return
    end

    nCols = size(W_bias,2);

    if nCols >= 5
        W_NN = W_bias(:,1:nCols-1);
        b_NN = W_bias(:,nCols);
    elseif nCols == 4
        W_NN = W_bias;
        b_NN = [];
        warning('W_bias tiene 4 columnas. Se interpreta como W sin bias.')
    elseif nCols == 1
        b_NN = W_bias(:,1);
        warning('W_bias tiene 1 columna. Se interpreta como bias sin pesos.')
    else
        W_NN = W_bias(:,1:nCols-1);
        b_NN = W_bias(:,nCols);
        warning('W_bias no tiene 5 columnas. Se toma la ultima columna como bias y las anteriores como W.')
    end
end

function formatAxes(fs)
    grid on
    box on
    set(gca, 'FontSize', fs, 'LineWidth', 1.1)
end

function plotMatrixSignals(t, Y, lw)
    for k = 1:size(Y,2)
        plot(t, Y(:,k), 'LineWidth', lw)
        hold on
    end
end

function labels = makeLegend(prefix, n)
    labels = strings(1,n);
    for k = 1:n
        labels(k) = prefix + "_" + string(k);
    end
end

function savePaperFig(figHandle, outDir, fileName, doExport)
    if doExport
        exportgraphics(figHandle, fullfile(outDir, fileName), 'ContentType', 'vector')
    end
end
