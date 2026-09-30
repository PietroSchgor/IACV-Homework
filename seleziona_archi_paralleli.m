function pts = seleziona_archi_paralleli(N, v3)
% SELEZIONA_ARCHI_PARALLELI Seleziona coppie di punti assistita dal punto di fuga.
%
%   INPUT:
%       N  - Numero di coppie da selezionare.
%       v3 - Punto di fuga [x; y; w] (necessario per la linea guida).
%
%   OUTPUT:
%       pts - Matrice 2x(2N) organizzata come:
%             [x_a1 ... x_an  x_b1 ... x_bn]
%             [y_a1 ... y_an  y_b1 ... y_bn]

    % Controllo preliminare sulla figura
    if isempty(get(groot, 'CurrentFigure'))
        figure; 
        axis([0 10 0 10]); 
    else
        axis manual;
        hold on;
    end
    
    % Assicuriamoci che v3 sia un vettore colonna omogeneo
    v3 = v3(:);
    if length(v3) == 2, v3(3) = 1; end
    
    % Pre-allocazione matrici temporanee per punti A e B
    % Punti A (primi click)
    Points_A = zeros(2, N);
    % Punti B (secondi click)
    Points_B = zeros(2, N);
    
    disp('--- INIZIO SELEZIONE ARCHI ---');
    
    % Salviamo i limiti attuali degli assi
    x_limits = xlim;
    y_limits = ylim;

    for i = 1:N
        fprintf('\n>>> Coppia %d di %d\n', i, N);
        
        % --- 1. PRIMO CLICK (Punto A) ---
        [x1, y1, button1] = ginput(1);
        if isempty(button1), break; end 
        
        % Visualizza primo punto (Verde)
        h_p1 = plot(x1, y1, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
        
        % --- 2. DISEGNO LINEA GUIDA PROSPETTICA ---
        
        p1 = [x1; y1; 1];
        guide_line = cross(p1, v3);
        
        % Disegna linea guida
        h_guide = draw_clipped_line(guide_line, x_limits, y_limits, 'c--');
        drawnow;
        
        % --- 3. SECONDO CLICK (Punto B) ---
        [x2, y2, button2] = ginput(1);
        
        if isempty(button2)
            delete(h_p1); delete(h_guide);
            warning('Selezione interrotta.');
            break;
        end
        
        % --- 4. SALVATAGGIO COORDINATE ---
        Points_A(:, i) = [x1; y1];
        Points_B(:, i) = [x2; y2];
            
        % --- 5. VISUALIZZAZIONE FINALE ---
        delete(h_guide); % Rimuovi guida
        
        % Disegna segmento giallo
        plot([x1, x2], [y1, y2], 'y-', 'LineWidth', 1.5);
        
        % Etichette
        text(x1, y1, sprintf('a_{%d}', i), "Color", 'g', 'FontSize', 12, 'FontWeight', 'bold');
        plot(x2, y2, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
        text(x2, y2, sprintf('b_{%d}', i), "Color", 'g', 'FontSize', 12, 'FontWeight', 'bold');
        
        drawnow;
    end
    
    % Costruzione matrice finale concatenata: [Tutti gli A, Tutti i B]
    pts = [Points_A, Points_B];
    
    hold off;
end

% --- HELPER FUNCTION PER DISEGNARE LINEE OMOGENEE ---
function h = draw_clipped_line(l, xlims, ylims, style)
    a = l(1); b = l(2); c = l(3);
    pts = [];
    
    % Intersezioni con i 4 bordi del plot
    y = (-c - a*xlims(1)) / b; if y >= ylims(1) && y <= ylims(2), pts = [pts; xlims(1), y]; end
    y = (-c - a*xlims(2)) / b; if y >= ylims(1) && y <= ylims(2), pts = [pts; xlims(2), y]; end
    x = (-c - b*ylims(1)) / a; if x >= xlims(1) && x <= xlims(2), pts = [pts; x, ylims(1)]; end
    x = (-c - b*ylims(2)) / a; if x >= xlims(1) && x <= xlims(2), pts = [pts; x, ylims(2)]; end
    
    if size(pts, 1) >= 2
        pts = unique(pts, 'rows');
        if size(pts, 1) >= 2
            h = plot(pts([1 end], 1), pts([1 end], 2), style, 'LineWidth', 1);
        else
            h = plot([], []); 
        end
    else
        h = plot([], []);
    end
end