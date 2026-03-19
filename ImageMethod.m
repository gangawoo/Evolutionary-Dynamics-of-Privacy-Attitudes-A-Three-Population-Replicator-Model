%% Privacy Dynamics ODE Simulation
% Clear workspace
clear; clc; close all;

%% Parameters
% You can modify these values
alpha = 0.5;    % Conflict cost (try: 1.0 for Regime 1, 0.5 for Regime 2, 1.0 for Regime 3)
beta = 1.0;     % Alignment benefit (try: 0.5 for Regime 1, 1.0 for Regime 2, 1.0 for Regime 3)

% Time settings
t_start = 0;
t_end = 100;
tspan = [t_start t_end];

%% Multiple Initial Conditions to Test
% Each row: [u_S(0), u_M(0), u_O(0)]
initial_conditions = [
    0.34, 0.33, 0.33;  % Near interior equilibrium
    0.9, 0.05, 0.05;    % Near Strict vertex
    0.05, 0.9, 0.05;    % Near Moderate vertex
    0.05, 0.05, 0.9;    % Near Open vertex
    0.5, 0.3, 0.2;      % Random interior point 1
    0.2, 0.3, 0.5;      % Random interior point 2
    0.4, 0.4, 0.2;      % Random interior point 3
    0.33, 0.34, 0.33;   % Slightly off equilibrium
];

%% Colors for plotting
colors = lines(size(initial_conditions, 1));

%% Solve ODE for each initial condition
figure('Position', [100, 100, 1200, 800]);

for i = 1:size(initial_conditions, 1)
    u0 = initial_conditions(i, :);
    
    % Solve ODE
    [t, u] = ode45(@(t, u) privacy_ode(t, u, alpha, beta), tspan, u0);
    
    % Plot time series
    subplot(2, 4, i);
    plot(t, u(:,1), 'b-', 'LineWidth', 1.5, 'DisplayName', 'Strict'); hold on;
    plot(t, u(:,2), 'g-', 'LineWidth', 1.5, 'DisplayName', 'Moderate');
    plot(t, u(:,3), 'r-', 'LineWidth', 1.5, 'DisplayName', 'Open');
    xlabel('Time');
    ylabel('Population fraction');
    title(sprintf('IC: [%.2f, %.2f, %.2f]', u0(1), u0(2), u0(3)));
    legend('Location', 'best');
    grid on;
    ylim([0, 1]);
end

sgtitle(sprintf('Privacy Dynamics: α = %.1f, β = %.1f', alpha, beta));

%% Phase Space Plot on Simplex
figure('Position', [100, 100, 800, 600]);

% Plot simplex triangle
hold on;
triangle_x = [0, 1, 0.5, 0];
triangle_y = [0, 0, sqrt(3)/2, 0];
plot(triangle_x, triangle_y, 'k-', 'LineWidth', 2);

% Label vertices
text(-0.05, -0.03, 'Strict', 'FontSize', 12, 'FontWeight', 'bold');
text(1.02, -0.03, 'Moderate', 'FontSize', 12, 'FontWeight', 'bold');
text(0.48, 0.9, 'Open', 'FontSize', 12, 'FontWeight', 'bold');

% Plot trajectories for each initial condition
for i = 1:size(initial_conditions, 1)
    u0 = initial_conditions(i, :);
    [t, u] = ode45(@(t, u) privacy_ode(t, u, alpha, beta), tspan, u0);
    
    % Convert to barycentric coordinates for plotting
    x = u(:,2) + 0.5*u(:,3);  % x-coordinate in simplex
    y = (sqrt(3)/2) * u(:,3);  % y-coordinate in simplex
    
    plot(x, y, 'Color', colors(i,:), 'LineWidth', 1.5);
    plot(x(1), y(1), 'o', 'Color', colors(i,:), 'MarkerSize', 8, 'MarkerFaceColor', colors(i,:));
end

% Mark interior equilibrium
x_eq = 1/3 + 0.5*(1/3);
y_eq = (sqrt(3)/2)*(1/3);
plot(x_eq, y_eq, 'ko', 'MarkerSize', 10, 'MarkerFaceColor', 'k');
text(x_eq+0.02, y_eq, 'Interior Eq', 'FontSize', 10);

title(sprintf('Phase Space Trajectories: α = %.1f, β = %.1f', alpha, beta));
xlabel('x'); ylabel('y');
axis equal;
grid on;

%% Long-term behavior classification
fprintf('\n=== Long-term Behavior Summary ===\n');
fprintf('Parameters: α = %.2f, β = %.2f\n\n', alpha, beta);

for i = 1:size(initial_conditions, 1)
    u0 = initial_conditions(i, :);
    [t, u] = ode45(@(t, u) privacy_ode(t, u, alpha, beta), [0 200], u0);
    
    % Look at last 10% of time series
    n = length(t);
    last_third = round(2*n/3):n;
    u_end = u(last_third, :);
    
    % Check if converged to vertex
    if mean(u_end(:,1)) > 0.95
        fprintf('IC %d: [%.2f,%.2f,%.2f] → STRICT vertex\n', i, u0);
    elseif mean(u_end(:,2)) > 0.95
        fprintf('IC %d: [%.2f,%.2f,%.2f] → MODERATE vertex\n', i, u0);
    elseif mean(u_end(:,3)) > 0.95
        fprintf('IC %d: [%.2f,%.2f,%.2f] → OPEN vertex\n', i, u0);
    % Check if oscillating (limit cycle)
    elseif std(u_end(:,1)) > 0.05
        fprintf('IC %d: [%.2f,%.2f,%.2f] → LIMIT CYCLE\n', i, u0);
    % Check if converged to interior
    elseif abs(mean(u_end(:,1)) - 1/3) < 0.05
        fprintf('IC %d: [%.2f,%.2f,%.2f] → INTERIOR EQUILIBRIUM\n', i, u0);
    else
        fprintf('IC %d: [%.2f,%.2f,%.2f] → OTHER\n', i, u0);
    end
end

%% Parameter Sweep: Explore different (α, β) combinations
figure('Position', [100, 100, 1000, 400]);

% Test different parameter pairs
alpha_vals = [1.0, 0.5, 1.0];
beta_vals = [0.5, 1.0, 1.0];
regime_names = {'Regime 1: α > β', 'Regime 2: α < β', 'Regime 3: α = β'};

for p = 1:3
    subplot(1, 3, p);
    
    % Use a representative initial condition
    u0 = [0.5, 0.3, 0.2];
    [t, u] = ode45(@(t, u) privacy_ode(t, u, alpha_vals(p), beta_vals(p)), [0 100], u0);
    
    plot(t, u(:,1), 'b-', 'LineWidth', 1.5); hold on;
    plot(t, u(:,2), 'g-', 'LineWidth', 1.5);
    plot(t, u(:,3), 'r-', 'LineWidth', 1.5);
    xlabel('Time');
    ylabel('Population');
    title(regime_names{p});
    ylim([0, 1]);
    grid on;
    if p == 3
        legend('Strict', 'Moderate', 'Open', 'Location', 'best');
    end
end

sgtitle('Comparison of Three Regimes (Same Initial Condition)');

%% ODE Function Definition
function dudt = privacy_ode(t, u, alpha, beta)
    % Privacy dynamics ODE system
    % u = [u_S, u_M, u_O]
    
    % Fitness values (from your model)
    f_S = -0.8*u(2) + 0.5*u(3) - 2*alpha*u(1)*u(2) + 2*beta*u(1)*u(3);
    f_M = 0.8*u(1) - 0.6*u(3) + 2*beta*u(1)*u(3) - 2*alpha*u(2)*u(3);
    f_O = -0.5*u(1) + 0.6*u(2) - 2*alpha*u(1)*u(3) + 2*beta*u(2)*u(3);
    
    % Mean fitness
    f_bar = u(1)*f_S + u(2)*f_M + u(3)*f_O;
    
    % ODEs
    dudt = zeros(3,1);
    dudt(1) = u(1) * (f_S - f_bar);
    dudt(2) = u(2) * (f_M - f_bar);
    dudt(3) = u(3) * (f_O - f_bar);
end