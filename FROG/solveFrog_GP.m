function [res] = solveFrog_GP(I, initialGuess, beta, iterMax, eps)
% Generalized Projection
% I should be normalize as maximum equal to 1

if isempty(initialGuess)
    if isscalar(iterMax)
        iterMax_vanilla = floor(min(iterMax / 5, 200));
    else
        iterMax_vanilla = iterMax(1);
        iterMax = iterMax(2);
    end

    init = solveFrog_vanilla(I, [], iterMax_vanilla, eps);
    P = init.P;
else
    P = initialGuess(:);
    init.err = [];
    init.iter = 0;
end
res.err = zeros(1, iterMax);
i = 1;
while i <= iterMax
    [P, res.err(i)] = generalized_projection(I, P, 1, beta);
    if res.err(i) < eps
        break;
    end
    i = i + 1;
end
res.P = P ./ max(abs(P));

% [res.P, res.P_sp] = removeFirstOrderPhase(P);
res.iter = [init.iter, i-1];
res.err = [init.err, res.err(1:i-1)];

end

function sig = data_constraint(I, sig_sp, b)
% if b ==1: sig_sp = sqrt(I) .* exp(1i * angle(sig_sp));
sig_sp = sig_sp .* (sqrt(I) ./ abs(sig_sp)).^b;
sig_sp(isnan(sig_sp)) = 0;
sig = ifft(ifftshift(sig_sp, 1), [], 1);
end

function [P, err] = generalized_projection(I, P, b, beta)
[~, sig_sp] = TraceGenerate(P);
sig = data_constraint(I, sig_sp, b);

N = size(I, 1);
ind_plus = mod((-N / 2:N / 2 - 1) + (0:N - 1)', N) + 1;
ind_minus = flipud(mod(-ind_plus, N + 1));
ind_sig = ind_minus + (0:N - 1) * N;
% mask_minus = ones(N) - triu(ones(N), N / 2 + 1) - tril(ones(N), -2);
% mask_plus = flipud(mask_minus);

P_mat_plus = P(ind_plus);
P_mat_minus = P(ind_minus);
sig_mat = sig(ind_sig);

gradient = (-conj(sig) .* P_mat_plus + P_mat_plus .* conj(P_mat_plus) .* conj(P)) ...
    + (-conj(sig_mat) .* P_mat_minus + P_mat_minus .* conj(P_mat_minus) .* conj(P));
gradient = sum(gradient, 2);
% Z = norm(sig - P .* P_mat_plus, 'fro');
P = P - 2 * beta * conj(gradient);
err = TraceError(I, P);
% the calculation of gradient is same as below
% gradient = zeros(N, 1);
% % Z = 0;
% for j = 1:N
%     for k = 1:N
%         tj = j - 1 - N / 2;
%         tk = k - 1 - N / 2;
%         if tk - tj >= -N / 2 && tk - tj <= N / 2 - 1
%             ind = tk - tj + 1 + N / 2;
%             gradient(k) = gradient(k) - conj(sig(k, j)) * P(ind) + P(ind) * conj(P(ind)) * conj(P(k));
%             % Z = Z+abs(sig(k, j) - P(k) * P(ind))^2;
%         end
%         if tk + tj >= -N / 2 && tk + tj <= N / 2 - 1
%             ind = tk + tj + 1 + N / 2;
%             gradient(k) = gradient(k) - conj(sig(ind, j)) * P(ind) + P(ind) * conj(P(ind)) * conj(P(k));
%         end
%     end
% end

end