clc
clear

% Establish piecewise function of nozzle radius based on solidworks file
% List of x coordinates
x = linspace(0, 0.1791409, 100)';
radius = zeros(1, 100)';
% Assign radius based on nozzle dimensions
for i=1:1:size(radius)
    if x(i) < 0.10869
        radius(i) = 0.04175;
    elseif x(i) < 0.13568
        radius(i) = 0.15044 - x(i);
    else
        radius(i) = [(0.03127 - 0.01476) / 0.04536] * x(i) - 0.03462441;
    end
        
end

% Visually verify the nozzle is drawn correctly
% plot(x, radius)
% axis([0 0.18 0 0.18]);

% Establish area at each point along the radius
area = radius.^2 * pi;

% Now for actual calculations
% Declare constants
gamma = 1.2455;         % From CEA
M = 20.277;             % From CEA
Astar = 0.00068436;     % m^2,    from design parameters
T_total = 3202.3;       % K,      from design parameters
P_total = 30;           % Bar,    from design parameters
% Find density in kg/m^3; apply ideal gas law using P, T, and M above
Rs = 8314.5 / M;        % Specific gas constant
rho_total = (P_total * 10^5) / (Rs * T_total);

% Isentropic parameter vectors
mach = zeros(1, 100);
T_ratio = zeros(1, 100);
T_static = zeros(1, 100);
P_ratio = zeros(1, 100);
P_static = zeros(1, 100);
rho_ratio = zeros(1, 100);
rho_static = zeros(1, 100);
area_ratio = zeros(1, 100);

% Experimental values, read from excel file in same directory
mach_exp = flip(xlsread("Internal Circumferential Average Summary.xlsx",...
                        "S3:S102"))';
P_exp = flip(xlsread("Internal Circumferential Average Summary.xlsx",...
                        "J3:J102"))';
T_exp = flip(xlsread("Internal Circumferential Average Summary.xlsx",...
                        "K3:K102"))';
rho_exp = flip(xlsread("Internal Circumferential Average Summary.xlsx",...
                        "M3:M102"))';

% Use Aerospace Toolbox isentropic flow to get ratios at different x values
% on the engine
for i=1:1:size(radius)
    % Before nozzle throat, indicate subsonic portion of area ratio
    if x(i) < 0.13568
        [mach(i), T_ratio(i), P_ratio(i), rho_ratio(i), area_ratio(i)]...
        = flowisentropic(gamma, (area(i) / Astar), 'sub');
    % After it, use supersonic portion
    else
        [mach(i), T_ratio(i), P_ratio(i), rho_ratio(i), area_ratio(i)]... 
        = flowisentropic(gamma, (area(i) / Astar), 'sup');
    end
end

% Convert isentropic ratios to values along x-axis using total pressures
T_static = T_ratio * T_total;
P_static = P_ratio * P_total;
rho_static = rho_ratio * rho_total;

% Mach Plot Section
subplot(2, 2, 1);
plot(x, mach, 'Color', 'cyan','LineWidth', 1.5);
hold on
xline(0.13568, '--', 'A*', 'LineWidth', 1.1);
plot(x, mach_exp, 'Color', 'magenta','LineWidth', 1.5);
title("Average Mach Number");
xlabel("Longitudinal Position (m)");
ylabel("Mach Number");
xlim([0.1 0.179]);
legend('Analytical', '', 'Simulated', 'location', 'northwest');
hold off

% Static Pressure Plot Section
subplot(2, 2, 2);
plot(x, P_static, 'Color', 'cyan','LineWidth', 1.5);
hold on
xline(0.13568, '--', 'A*', 'LineWidth', 1.1);
plot(x, P_exp, 'Color', 'magenta','LineWidth', 1.5);
title("Average Static Pressure");
xlabel("Longitudinal Position (m)");
ylabel("Static Pressure (bar)");
xlim([0.1 0.179]);
legend('Analytical', '', 'Simulated', 'location', 'northwest');
hold off

% Static Temperature Plot Section
subplot(2, 2, 3);
plot(x, T_static, 'Color', 'cyan','LineWidth', 1.5);
hold on
xline(0.13568, '--', 'A*', 'LineWidth', 1.1);
plot(x, T_exp, 'Color', 'magenta','LineWidth', 1.5);
title("Average Static Temperature");
xlabel("Longitudinal Position (m)");
ylabel("Static Temperature (K)");
xlim([0.1 0.179]);
legend('Analytical', '', 'Simulated', 'location', 'southwest');
hold off

% Static Density Plot Section
subplot(2, 2, 4);
plot(x, rho_static, 'Color', 'cyan','LineWidth', 1.5);
hold on
xline(0.13568, '--', 'A*', 'LineWidth', 1.1);
plot(x, rho_exp, 'Color', 'magenta','LineWidth', 1.5);
title("Average Density");
xlabel("Longitudinal Position (m)");
ylabel("Density (kg/m^3)");
xlim([0.1 0.179]);
legend('Analytical', '', 'Simulated', 'location', 'southwest');
hold off

exportgraphics(gcf,'Analytical and Simulated Thermo Params.png'...
                  ,'Resolution',800)