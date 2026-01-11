close all;
clear;
clc;

%% 1. Khởi tạo biến (Giống main.m)
theta = (-90:0.1:90-0.1)*pi/180; % rad
lambda = 1; 
M = 12; % Số phần tử anten
desDirs_c = 0.0;

%% 2. Tạo phản hồi mảng (Array Response)
Q = 160; 
phi = 1;
eqDir = -1:phi/Q:1-phi/Q;
Aq = generateQuantizedArrResponse(M, eqDir);

%% 3. Tạo mẫu tham chiếu (Reference Beam)
[PdM, P_refGen, W0] = generateDesPattern(eqDir, sin(desDirs_c), Aq);

% Các hướng quan trọng cần tối ưu (alpha)
alpha = sort([find(ismember(eqDir, eqDir(1:4:end))), find(PdM)]);

%% 4. Cấu hình và Chạy Steady-State Genetic Algorithm (SSGA)
fprintf('Đang khởi chạy Steady-State Genetic Algorithm (SSGA)...\n');

% Số lượng biến: M phần thực + M phần ảo
nVars = 2 * M; 

% Định nghĩa hàm mục tiêu
FitnessFcn = @(x) jcas_fitness(x, Aq, PdM, alpha);

% Cấu hình Steady-State GA
% Ý tưởng: Trong SSGA, phần lớn quần thể được giữ lại (Elite), chỉ một số ít cá thể mới
% được sinh ra để thay thế các cá thể tồi nhất trong mỗi thế hệ.
PopulationSize = 200;
ReplacementRate = 0.1; % Thay thế 10% dân số mỗi thế hệ (20 cá thể)
EliteCount = floor(PopulationSize * (1 - ReplacementRate)); % Giữ lại 180 cá thể (90%)

% Sử dụng kết quả Capon (W0) làm khởi tạo
initial_individual = [real(W0'), imag(W0')]; 

options = optimoptions('ga', ...
    'Display', 'iter', ...          
    'PlotFcn', @gaplotbestf, ...    
    'PopulationSize', PopulationSize, ...      
    'InitialPopulationMatrix', initial_individual, ... 
    'EliteCount', EliteCount, ...   % QUAN TRỌNG: EliteCount rất cao đặc trưng cho SSGA
    'MaxGenerations', 200, ...      % Đặt về 200 để so sánh ngang bằng với các thuật toán khác
    'FunctionTolerance', 1e-8, ...  
    'MaxStallGenerations', Inf);    % Đặt là Inf để ép chạy hết số thế hệ MaxGenerations

% Gọi hàm GA
[x_opt, fval] = ga(FitnessFcn, nVars, [], [], [], [], [], [], [], options);

%% 5. Hiển thị kết quả
% Tái tạo vector trọng số phức từ kết quả GA
W_ga = x_opt(1:M)' + 1i * x_opt(M+1:end)';

% Tính toán búp sóng kết quả
P_ga = abs(W_ga' * Aq);

% Vẽ đồ thị so sánh
figure;
plot(eqDir, zeros(size(eqDir)), 'k-'); % Trục 0
hold on;
plot(eqDir, 10*log10(PdM/max(PdM)), 'm-*', 'LineWidth', 1); % Mẫu mong muốn
hold on;
plot(eqDir, 10*log10(P_refGen/max(P_refGen)), '--k'); % Mẫu ULA thông thường
hold on;
plot(eqDir, 10*log10(P_ga/max(P_ga)), 'r', 'LineWidth', 1.5); % Kết quả SSGA

legend('Zero Line', 'Desired Pattern', 'Conventional 12-element ULA', 'Optimized (Steady-State GA)', ...
    'Location', 'northoutside', 'NumColumns', 4);
xlabel("Equivalent directions");
ylabel("|A|, dB");
xlim([-1 1]);
ylim([-35, 1]);
title('Kết quả tối ưu hóa Beamforming bằng Steady-State GA');
grid on;

fprintf('Hoàn tất Steady-State GA. Giá trị hàm mục tiêu (Cost): %f\n', fval);
