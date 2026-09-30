function A = seleziona_midpoints(N, v3)
% SELEZIONA_MIDPOINTS (Versione con Auto-Salvataggio)
% ... (tutti i commenti e help rimangono uguali) ...

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

    A = zeros(2, N); % Pre-allocazione
    
    disp('--- INIZIO SELEZIONE ---');
    disp('1. Clicca il primo punto.');
    disp('2. Segui la linea guida ciano.');
    disp('3. Clicca il secondo punto.');
    
    x_limits = xlim;
    y_limits = ylim;

    for i = 1:N
        fprintf('\n>>> Coppia %d di %d\n', i, N);
        
        % --- 1. PRIMO CLICK ---
        [x1, y1, button1] = ginput(1);
        if isempty(button1), break; end 
        
        h_p1 = plot(x1, y1, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
        
        % --- 2. DISEGNO LINEA GUIDA ---
        p1 = [x1; y1; 1];
        guide_line = cross(p1, v3);
        h_guide = draw_clipped_line(guide_line, x_limits, y_limits, 'b');
        drawnow;
        
        % --- 3. SECONDO CLICK ---
        [x2, y2, button2] = ginput(1);
        
        if isempty(button2)
            delete(h_p1); delete(h_guide);
            warning('Selezione interrotta.');
            break;
        end
        
        p2 = [x2; y2; 1];
        
        % --- 4. CALCOLO MIDPOINT ---
        try
            midpoint_h = midpoint_crossratio(p1, p2, v3);
            
            if length(midpoint_h) == 3
                midpoint = midpoint_h(1:2) ./ midpoint_h(3);
            else
                midpoint = midpoint_h;
            end
            
            A(:, i) = midpoint;
            
            % --- 5. VISUALIZZAZIONE ---
            delete(h_guide); 
            plot([x1, x2], [y1, y2], 'y-', 'LineWidth', 1.5);
            text(x1, y1, sprintf('a_{%d}', i), "Color", 'g', 'FontSize', 12, 'FontWeight', 'bold');
            plot(x2, y2, 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 6);
            
            plot(midpoint(1), midpoint(2), 'rx', 'MarkerSize', 12, 'LineWidth', 2);
            text(midpoint(1), midpoint(2)-10, sprintf('m_{%d}', i), ...
                'Color', 'r', 'FontSize', 12, 'FontWeight', 'bold');
            
            drawnow;
            
        catch err
            warning('Errore: %s', err.message);
            delete(h_p1); delete(h_guide);
            i = i - 1; 
        end
    end
    
    hold off;
    
    % === NUOVA PARTE: SALVATAGGIO AUTOMATICO ===
    fprintf('Salvataggio midpoints in "midpoints_backup.mat"... ');
    save('midpoints_backup.mat', 'A');
    fprintf('Fatto.\n');
end

% ... (La funzione draw_clipped_line rimane invariata) ...
function h = draw_clipped_line(l, xlims, ylims, style)
    a = l(1); b = l(2); c = l(3);
    pts = [];
    y = (-c - a*xlims(1)) / b; if y >= ylims(1) && y <= ylims(2), pts = [pts; xlims(1), y]; end
    y = (-c - a*xlims(2)) / b; if y >= ylims(1) && y <= ylims(2), pts = [pts; xlims(2), y]; end
    x = (-c - b*ylims(1)) / a; if x >= xlims(1) && x <= xlims(2), pts = [pts; x, ylims(1)]; end
    x = (-c - b*ylims(2)) / a; if x >= xlims(1) && x <= xlims(2), pts = [pts; x, ylims(2)]; end
    if size(pts, 1) >= 2
        pts = unique(pts, 'rows');
        if size(pts, 1) >= 2, h = plot(pts([1 end], 1), pts([1 end], 2), style, 'LineWidth', 1); else, h = plot([], []); end
    else, h = plot([], []); end
end