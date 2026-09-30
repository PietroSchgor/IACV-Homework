clc; clear; close all;

%% ========================================================================
%% 1. SETUP & HYPERPARAMETERS
%% ========================================================================
input_img = imread('San Maurizio.jpg');
input_img = imresize(input_img, 0.7);

CONFIG.extract = false; % Se true, riesegue l'estrazione linee
plot_on        = false;  % Abilita i grafici di debug delle linee

%% ========================================================================
%% 2. FEATURE EXTRACTION & VANISHING GEOMETRY
%% ========================================================================
disp('--- 1. Feature Extraction & Vanishing Points ---');

% Estrazione linee (funzione esterna)
[l_lines, m_lines, w_lines] = extract_lines(input_img, CONFIG, plot_on);

% --- Calcolo Punti di Fuga (Vanishing Points) ---
% Vx: Direzione orizzontale
vx = cross(l_lines{1}, l_lines{3});
vx = vx / vx(3);

% Vy: Direzione verticale
vy = cross(m_lines{1}, m_lines{3});
vy = vy / vy(3);

% Vz: Direzione asse cilindro (profondità)
vz = cross(w_lines{1}, w_lines{3});
vz = vz / vz(3);

% --- Calcolo Linea d'Orizzonte ---
horizon = cross(vx, vy);
horizon = horizon / horizon(3);

disp('horizon:');
disp(horizon);

%% FIGURA 1: Geometria Proiettiva
figure('Name', '1. Perspective Geometry', 'Units', 'normalized', 'Position', [0.05 0.5 0.45 0.4]);
imshow(input_img); hold on;
[h, w, ~] = size(input_img);

% Plot Punti di Fuga
plot(vx(1), vx(2), 'ro', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Vx');
plot(vy(1), vy(2), 'go', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Vy');
plot(vz(1), vz(2), 'mo', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Vz');

% Plot Orizzonte
padding = 200;
x_lims = [1, w]; 
if vx(1) < 1, x_lims(1) = vx(1) - padding; end
if vy(1) > w, x_lims(2) = vy(1) + padding; end
line([vx(1), vy(1)], [vx(2), vy(2)], 'Color', 'b', 'LineWidth', 1.5, 'DisplayName', 'Horizon');

% Plot Linee Guida (Vz)
for k = 1:min(2, length(w_lines))
    l = w_lines{k};
    y_l = [1, h]; 
    x_l = (-l(2)*y_l - l(3))/l(1);
    plot(x_l, y_l, 'm--', 'LineWidth', 0.5, 'HandleVisibility', 'off');
end

legend show; title('Vanishing Points & Horizon');
axis([min([vx(1), 1])-100, max([vy(1), w])+100, min([vx(2), vy(2), 1])-100, max([vx(2), vy(2), h])+100]);
hold off;

%% ========================================================================
%% 3. CONIC FITTING & RECTIFICATION
%% ========================================================================
disp('--- 2. Conic Fitting & Rectification ---');

N_midpoints = 12;

% --- Caricamento / Selezione Punti per Conica ---

if exist('mat/midpoints_backup.mat', 'file')
    % Opzione 1: Recupera i dati salvati
    disp('Caricamento punti salvati...');
    midpoints = extracted_midpoint();
    
    % visualizzazione immagine
    figure; imshow(input_img); hold on;
    plot(midpoints(1,:), midpoints(2,:), 'rx', 'MarkerSize', 12, 'LineWidth', 2);
    title('Midpoints Recuperati da File');
else 
    % Opzione 2: Se il file non esiste, devi selezionarli
    figure('Name', 'Input Selection'); 
    imshow(input_img); 
    disp('Nessun salvataggio trovato. Inizio selezione manuale...');
    midpoints = seleziona_midpoints(N_midpoints, vz);
end

% --- Direct Algebraic Conic Fit (DLT) ---
x_data = midpoints(1, :)'; 
y_data = midpoints(2, :)';
D_mat = [x_data.^2, x_data.*y_data, y_data.^2, x_data, y_data, ones(size(x_data))];
[~,~,V_svd] = svd(D_mat, 0);
par_alg = V_svd(:,end); 
par_alg = par_alg / par_alg(end);
[a1,b1,c1,d1,e1,f1] = deal(par_alg(1), par_alg(2), par_alg(3), par_alg(4), par_alg(5), par_alg(6));

% Matrice Conica C1
C1 = [a1,   b1/2, d1/2;
      b1/2, c1,   e1/2;
      d1/2, e1/2, f1];
C1 = C1 / C1(3,3);

disp('Conic matrix C1:');
disp(C1);

% Centro Proiettivo (Polo)
det_top = a1*c1 - (b1/2)^2;
xc = (b1/2 * e1/2 - c1 * d1/2) / det_top;
yc = (b1/2 * d1/2 - a1 * e1/2) / det_top;

% --- Generazione Ellisse per Plot ---
pg = AtoG(par_alg); 
t_vals = linspace(0, 2*pi, 100);
x_ell = pg(1) + pg(3)*cos(t_vals)*cos(pg(5)) - pg(4)*sin(t_vals)*sin(pg(5));
y_ell = pg(2) + pg(3)*cos(t_vals)*sin(pg(5)) + pg(4)*sin(t_vals)*cos(pg(5));


%% Compute the position of a non-apical nodal point on the choosen plane.
figure; imshow(input_img); hold on;
m_5 = midpoints(:,5);
m_5 = [m_5; 1];
plot(m_5(1), m_5(2), 'rx', 'MarkerSize', 12, 'LineWidth', 2);

Rm_5 = H_R*m_5;
Rm_5 = Rm_5 / Rm_5(3);

disp('--------------------------------------------------');
disp(['Position of nodal point m_5  on the Image Plane (pixels):']);
disp(m_5');
disp(['Position of nodal point m_5 on the Metric Plane (rectified pixels):']);
disp(Rm_5');
disp('--------------------------------------------------');



%% FIGURA 2: Fitting Conica
figure('Name', '2. Conic Fitting', 'Units', 'normalized', 'Position', [0.51 0.5 0.45 0.4]);
imshow(input_img); hold on;
plot(x_data, y_data, 'rx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Midpoints');
plot(x_ell, y_ell, 'b-', 'LineWidth', 2, 'DisplayName', 'Fitted Ellipse');
plot(xc, yc, 'gx', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Conic Center');
legend('show', 'Location', 'NorthWest'); 
hold off;

%% ========================================================================
%% 4. RECTIFICATION (AFFINE & METRICA)
%% ========================================================================
disp('--- 3. Rectification ---');

% --- Affine Rectification ---
H_a = [1, 0, 0; 
       0, 1, 0; 
       horizon(1), horizon(2), horizon(3)];
H_a = H_a / H_a(3,3);

disp('Affine rectification matrix H_a:');
disp(H_a);

tform_aff = projective2d(H_a');
input_img_aff = imwarp(input_img, tform_aff );

% Trasformazione conica
H_inv = inv(H_a);
Q = H_inv' * C1 * H_inv;
Q = Q / Q(3,3); 

% --- Metric Rectification ---
par_geo = AtoG([Q(1,1), 2*Q(1,2), Q(2,2), 2*Q(1,3), 2*Q(2,3), Q(3,3)]);
axes_len = par_geo(3:4);
alpha_rot = par_geo(5);

U = [cos(alpha_rot), -sin(alpha_rot); sin(alpha_rot), cos(alpha_rot)];
S_scale = diag([1, axes_len(1)/axes_len(2)]);
K_aff = U * S_scale * U';

H_b = [K_aff, zeros(2,1); zeros(1,2), 1];
H_R = H_b * H_a; % Omografia Rettificante Finale

disp('Metric rectification matrix H_R:');
disp(H_R);

tform_met = projective2d(H_R');
input_img_met = imwarp(input_img, tform_met); 

% Conica Metrica 
H_R_inv = inv(H_R);
Q_met = H_R_inv' * C1 * H_R_inv;
Q_met = Q_met / Q_met(3,3);

%% FIGURA 3: Confronto Rettificazione
figure('Name', '3. Rectification Stages', 'Units', 'normalized', 'Position', [0.05 0.05 0.45 0.4]);

% Subplot Affine
subplot(1,2,1);
imshow(input_img_aff); title('Affine Rectification'); hold on;

% Subplot Metrico
subplot(1,2,2);
imshow(input_img_met); title('Metric Rectification'); hold on;

% --- Visualizzazione Extra (Crop & Rotazione per Report) ---
% Affine
figure('Name', 'Report: Affine Rotated');
top_left_corner_aff = input_img_aff(1:1800, 1:1500, :);
imshow(imrotate(top_left_corner_aff, -90));
% Metrica
figure('Name', 'Report: Metric Rotated');
top_left_corner_met = input_img_met(1:600, 700:1220, :);
imshow(imrotate(top_left_corner_met, -90));

%% ========================================================================
%% 5. CAMERA CALIBRATION (K MATRIX)
%% ========================================================================
disp('--- 4. Calibration ---');

H_cal = inv(H_R);
h1 = H_cal(:,1); 
h2 = H_cal(:,2);
L = horizon; 
V = vz;

% Sistema lineare per IAC (Image of Absolute Conic)
A_sys = zeros(4, 4);
% Vincoli ortogonalità colonne omografia
A_sys(1,:) = [h1(1)*h2(1)+h1(2)*h2(2), h1(1)*h2(3)+h1(3)*h2(1), h1(2)*h2(3)+h1(3)*h2(2), h1(3)*h2(3)];
% Vincoli lunghezza colonne omografia
A_sys(2,:) = [(h1(1)^2+h1(2)^2)-(h2(1)^2+h2(2)^2), 2*(h1(1)*h1(3)-h2(1)*h2(3)), 2*(h1(2)*h1(3)-h2(2)*h2(3)), h1(3)^2-h2(3)^2];
% Vincoli Punto di Fuga - Orizzonte
A_sys(3,:) = [V(1)*L(3), V(3)*L(3)-V(1)*L(1), -V(2)*L(1), -V(3)*L(1)];
A_sys(4,:) = [V(2)*L(3), -V(1)*L(2), V(3)*L(3)-V(2)*L(2), -V(3)*L(2)];

[~, ~, V_sol] = svd(A_sys);
w_vec = V_sol(:, end);

% Costruzione matrice omega e decomposizione Cholesky
omega = [w_vec(1), 0, w_vec(2); 
         0, w_vec(1), w_vec(3); 
         w_vec(2), w_vec(3), w_vec(4)];
omega = omega / w_vec(4);

K = inv(chol(omega));
K = K / K(3,3);

disp('Calibration Matrix K:');
disp(K);

%% ========================================================================
%% 6. 3D RECONSTRUCTION
%% ========================================================================
disp('--- 5. 3D Reconstruction ---');

cache_file = 'mat/pts_archi_paralleli.mat';
N_pts = 12;

% --- Gestione Cache Selezione Punti ---
if exist(cache_file, 'file')
    fprintf('Caricamento punti archi da "%s"...\n', cache_file);
    load(cache_file, 'pts');
    
    figure('Name', 'Parallel Diagonal Arcs'); 
    imshow(input_img); hold on;
    plot(pts(1,:), pts(2,:), 'go', 'LineWidth', 2);
    title('Punti Archi Caricati');
    hold off;
else
    fprintf('File non trovato. Avvio selezione manuale...\n');
    figure('Name', 'Parallel Diagonal Arcs');
    imshow(input_img);
    pts = seleziona_archi_paralleli(N_pts, vz); 
    save(cache_file, 'pts');
end

% --- Ricostruzione Geometrica ---
pts(3, :) = 1; % Coordinate omogenee

% --- Plot Arco estratto ---
figure('Name', 'Arc Visualization'); 
imshow(input_img); hold on;

% Estrazione coordinate
x = pts(1, 1:N_pts);
y = pts(2, 1:N_pts);

plot(x, y, '-o', 'Color', 'm', 'LineWidth', 2, ...              
    'MarkerSize', 6, 'MarkerEdgeColor', 'b', ...      
    'MarkerFaceColor', 'm', 'DisplayName', 'Extracted Arc'); 

% Back-projection raggi
points_3d_rays = zeros(3, 2*N_pts);
for i = 1 : 2*N_pts
    ray = K \ pts(:,i);
    points_3d_rays(:,i) = ray / norm(ray); 
end

% Separazione Archi A e B
rays_A = points_3d_rays(:, 1:N_pts);
rays_B = points_3d_rays(:, N_pts+1:end);

axis_direction = K \ vz; 
axis_direction = axis_direction / norm(axis_direction);

% Triangolazione (Teorema dei Seni)
d_phys = 2; % Distanza fisica nota
A_3D = zeros(3, N_pts);
B_3D = zeros(3, N_pts);

for i = 1:N_pts
    theta = acos(rays_A(:, i)' * rays_B(:, i));
    alpha = acos(rays_A(:, i)' * axis_direction);
    beta  = pi - (theta + alpha);
    
    norm_A = d_phys * sin(beta) / sin(theta);
    norm_B = d_phys * sin(alpha) / sin(theta);
    
    A_3D(:, i) = norm_A * rays_A(:, i);
    B_3D(:, i) = norm_B * rays_B(:, i);
end

%% ========================================================================
%% 7. CYLINDER AXIS LOCALIZATION
%% ========================================================================
disp('--- 6. Axis Localization ---');

% 1. Back-projection centro della conica
center_input_img = [xc; yc; 1];
r_c = K \ center_input_img; 
r_c = r_c / norm(r_c);

% 2. Definizione Piano Apicale (usando un punto ricostruito, es. A_5)
idx_anchor = 5;
m_anchor = A_3D(:, idx_anchor); 

% 3. Intersezione Raggio - Piano
k_plane = -axis_direction' * m_anchor;
lambda = -k_plane / (axis_direction' * r_c);

% Centro Asse 3D
CC = lambda * r_c;
Camera = [0; 0; 0]; % Posizione camera

%% ========================================================================
%% 8. FINAL VISUALIZATION
%% ========================================================================
% --- Figura A: Principal Point ---
figure('Name','Calibration: Principal Point');
imshow(input_img); hold on;
[h, w, ~] = size(input_img);

plot(K(1,3), K(2,3), 'rx', 'MarkerSize', 15, 'LineWidth', 3, 'DisplayName', 'Computed PP');
plot(w/2, h/2, 'go', 'MarkerSize', 10, 'LineWidth', 2, 'DisplayName', 'Image Center');

% --- MODIFICA QUI ---
lgd = legend('show'); 
lgd.FontSize = 14;    

hold off;

%% ========================================================================
% Configurazione delle 4 viste "Tridimensionali"
views_config = {
    [-37.5, 30], 'Isometric View (Standard)';      
    [-135, 25],  'Rear-Side View';                  
    [45, 10],    'Low Angle (Worm''s Eye)';         
    [20, 60],    'High Angle (Bird''s Eye)'         
};

% --- CALCOLO RETTA ASSE ---
t_infinite = [-3, 3]; 
Axis_Line = CC + axis_direction * t_infinite; 

% Ciclo per generare 4 figure distinte
for k = 1:4
    % 1. Crea figura con sfondo finestra bianco
    figure('Name', sprintf('3D Recon - %s', views_config{k, 2}), ...
           'Color', 'w'); 
    hold on;
    
    % --- Plot Oggetti ---
    plot3(Axis_Line(1,:), Axis_Line(2,:), Axis_Line(3,:), 'b-.', ...
        'LineWidth', 1.5, 'DisplayName', 'Cylinder Axis');
    
    plot3(A_3D(1,:), A_3D(2,:), A_3D(3,:), 'mo-', 'LineWidth', 1.5, ...
        'MarkerSize', 4, 'MarkerFaceColor', 'm', 'DisplayName', 'Arc A');
    
    plot3(Camera(1), Camera(2), Camera(3), 'go', 'MarkerSize', 8, ...
        'LineWidth', 3, 'DisplayName', 'Camera');
    text(Camera(1), Camera(2), Camera(3)-0.5, ' Camera', 'FontSize', 10, ...
        'Color', 'r', 'FontWeight', 'bold');
    
    % --- Estetica ---
    axis equal;
    xlabel('X'); ylabel('Y'); zlabel('Z');
    
    %  Sfondo Bianco + Griglia Nera 
    grid on;
    set(gca, 'Color', 'w', 'GridColor', 'k', ...    
             'GridAlpha', 0.25, 'LineWidth', 1.0);       
    
    % Imposta vista e prospettiva
    view(views_config{k, 1});
    camproj('perspective'); 
    camlight('headlight'); 
    lighting gouraud;
    
    hold off;
end



%% ========================================================================
%% Creazione File results.txt
%% ========================================================================
filename = 'results.txt';

% 1. Prepariamo i dati e i nomi in due liste corrispondenti
data_to_save = {vx, vy, vz, horizon, H_R, C1, K, midpoints, A_3D};
var_names    = ["vx (Vanishing Point X)", ...
                "vy (Vanishing Point Y)", ...
                "vz (Vanishing Point Z)", ...
                "horizon (Line at Infinity)", ...
                "H_R (Metric Rectification Matrix)", ...
                "C1 (Conic Matrix)", ...
                "K (Calibration Matrix)", ...
                "midpoints (2D Points used for Conic)", ...
                "A_3D (3D Reconstructed Arc Points)"];

% 2. Inizializzazione del file
writelines("=== REPORT RISULTATI ===", filename);
writelines("Generato il: " + string(datetime('now')), filename, 'WriteMode', 'append');

% 3. Ciclo per salvare ogni variabile
for i = 1:length(data_to_save)
    % Aggiunge una riga vuota per separare i blocchi
    writelines("", filename, 'WriteMode', 'append');
    
    % Scrive il nome della variabile 
    writelines("### " + var_names(i) + " ###", filename, 'WriteMode', 'append');
    
    % Scrive la matrice o il vettore numerico
    writematrix(data_to_save{i}, filename, 'WriteMode', 'append');
end

disp(['File "', filename, '" creato con successo!']);
