function cost = jcas_fitness(x, Aq, PdM, alpha)
    % x: Vector biến tối ưu (gồm phần thực và phần ảo nối tiếp)
    % Aq: Phản hồi mảng (Array Response)
    % PdM: Mẫu mong muốn (Desired Pattern Magnitude)
    % alpha: Các chỉ số hướng quan trọng cần tối ưu
    
    M = length(x) / 2;
    % Tách phần thực và ảo để tái tạo vector trọng số phức w
    w_real = x(1:M);
    w_imag = x(M+1:end);
    w = w_real(:) + 1i * w_imag(:);
    
    % Tính toán búp sóng hiện tại (Pattern Magnitude)
    % w' * Aq tạo ra phản hồi phức, lấy abs để được biên độ
    PM = abs(w' * Aq);
    
    % Tính sai số tại các điểm alpha
    % Mục tiêu: Giảm thiểu sự khác biệt giữa mẫu tạo ra và mẫu mong muốn
    diff = PM(alpha) - PdM(alpha);
    
    % Hàm chi phí là tổng bình phương sai số (hoặc tổng sai số tuyệt đối)
    cost = sum(abs(diff).^2); 
end
