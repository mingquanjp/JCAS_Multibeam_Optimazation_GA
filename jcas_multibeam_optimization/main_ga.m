close all;
clear;
clc;

%% 1. Khởi tạo biến 
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

%% 4. Cấu hình và Chạy Thuật toán Di truyền (GA)
fprintf('Đang khởi chạy Genetic Algorithm (GA)...\n');

% Số lượng biến: M phần thực + M phần ảo
nVars = 2 * M; 

% Định nghĩa hàm mục tiêu
FitnessFcn = @(x) jcas_fitness(x, Aq, PdM, alpha);

% Tùy chọn cho GA
% Sử dụng kết quả Capon (W0) làm khởi tạo để hội tụ nhanh hơn
initial_individual = [real(W0'), imag(W0')]; 

options = optimoptions('ga', ...
    'Display', 'iter', ...          % Hiển thị tiến trình từng thế hệ
    'PlotFcn', @gaplotbestf, ...    % Vẽ đồ thị hội tụ
    'MaxGenerations', 200, ...      % Số thế hệ tối đa
    'PopulationSize', 200, ...      % Kích thước quần thể
    'InitialPopulationMatrix', initial_individual, ... % Khởi tạo thông minh
    'FunctionTolerance', 1e-6, ...  % Dừng khi không còn cải thiện đáng kể
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
plot(eqDir, 10*log10(P_ga/max(P_ga)), 'r', 'LineWidth', 1.5); % Kết quả GA

legend('Zero Line', 'Desired Pattern', 'Conventional 12-element ULA', 'Optimized (GA)', ...
    'Location', 'northoutside', 'NumColumns', 4);
xlabel("Equivalent directions");
ylabel("|A|, dB");
xlim([-1 1]);
ylim([-35, 1]);
title('Kết quả tối ưu hóa Beamforming bằng Genetic Algorithm');
grid on;

fprintf('Hoàn tất. Giá trị hàm mục tiêu (Cost): %f\n', fval);
