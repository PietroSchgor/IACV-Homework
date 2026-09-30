function [h_lines, l_lines, m_lines] = extract_lines(IMG, CONFIG, DEBUG)
    folder_name = 'mat';
    save_file = fullfile(folder_name, 'extracted_features.mat');
    
    if ~exist(folder_name, 'dir')
        mkdir(folder_name);
    end
    
    v_segments = {}; l_segments = {}; h_segments = {};
    
    % --- SECTION 1: DATA ACQUISITION ---
    if CONFIG.extract == false && exist(save_file, 'file')
        fprintf('Loading segments from %s...\n', save_file);
        data = load(save_file);
        v_segments = data.v_segments;
        l_segments = data.l_segments;
        h_segments = data.h_segments;


        if DEBUG
            figure('Name', 'Fig 1: Original Image Overlay');
            imshow(IMG); hold on;
            plot_helper(v_segments, 'b--'); 
            plot_helper(l_segments, 'g--'); 
            plot_helper(h_segments, 'w--'); 
            %title('Given Segments');
        end
    else
        fprintf('Starting manual selection...\n');
        [v_segments, l_segments, h_segments] = manual_selection_loop(IMG);
        save(save_file, 'v_segments', 'l_segments', 'h_segments');
    end

    [rows, cols, ~] = size(IMG);
    % CUSTOM NAMES
    v_name = "l"; l_name = "m"; h_name = "w";

    if DEBUG
        % --- SECTION 2: PLOT SEGMENTS ON WHITE BACKGROUND ---
        figure('Name', 'Fig 2: Feature Map (Segments)');
        imshow(ones(rows, cols, 3)); 
        hold on;
        plot_and_label_segments(v_segments, v_name, 'r');
        plot_and_label_segments(l_segments, l_name, 'r');
        plot_and_label_segments(h_segments, h_name, 'r');
        %title('Extracted Segments');
        hold off;
    
        % --- SECTION 3: PLOT INFINITE LINES ON WHITE BACKGROUND (Colored) ---
        figure('Name', 'Fig 3: Infinite Line Map');
        imshow(ones(rows, cols, 3)); 
        hold on;
        % Assigning different colors for each category here:
        plot_infinite_lines(v_segments, v_name, 'b', cols, rows); % Blue
        plot_infinite_lines(l_segments, l_name, 'g', cols, rows); % Green
        plot_infinite_lines(h_segments, h_name, 'r', cols, rows); % Red
        title('Extracted Infinite Lines Map (Colored)');
        hold off;
    end

    % --- SECTION 4: ASSIGN OUTPUTS ---
    h_lines = segments_to_lines(v_segments);
    l_lines = segments_to_lines(l_segments);
    m_lines = segments_to_lines(h_segments);
end

% --- HELPER: Plot Infinite Lines with Names and Specific Colors ---
function plot_infinite_lines(segments, prefix, color_char, img_w, img_h)
    offset_dist = 15; 
    for k = 1:length(segments)
        p1 = segments{k}.point1;
        p2 = segments{k}.point2;
        
        a = p1(2) - p2(2);
        b = p2(1) - p1(1);
        c = -(a*p1(1) + b*p1(2));
        
        if abs(b) > abs(a)
            x_vals = [1, img_w];
            y_vals = (-a*x_vals - c) / b;
        else
            y_vals = [1, img_h];
            x_vals = (-b*y_vals - c) / a;
        end
        plot(x_vals, y_vals, 'Color', color_char, 'LineWidth', 1.5);
        
        tx = (p1(1) + p2(1)) / 2;
        ty = (p1(2) + p2(2)) / 2;
        dx = p2(1) - p1(1); dy = p2(2) - p1(2);
        len = sqrt(dx^2 + dy^2);
        
        if len > 0
            nx = -dy / len; ny = dx / len;
            text_x = tx + nx * offset_dist;
            text_y = ty + ny * offset_dist;
        else
            text_x = tx; text_y = ty;
        end
        
        label_str = sprintf('%s_{%d}', prefix, k);
        text(text_x, text_y, label_str, 'Interpreter', 'tex', 'Color', 'k', ...
            'FontSize', 20, 'FontName', 'Times New Roman', 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end
end

% --- HELPER: Convert Endpoints to Line Equation (ax + by + c = 0) ---
function lines = segments_to_lines(segments)
    lines = cell(size(segments));
    for k = 1:length(segments)
        p1 = segments{k}.point1;
        p2 = segments{k}.point2;
        
        % Standard coefficients
        a = p1(2) - p2(2);
        b = p2(1) - p1(1);
        c = -(a*p1(1) + b*p1(2));
        
        % Return as a 3x1 homogeneous vector
        lines{k} = [a; b; c]; 
    end
end

% --- HELPER: Original Segment Plotting with Labels (Unchanged) ---
function plot_and_label_segments(segments, prefix, color_char)
    offset_dist = 12;
    for k = 1:length(segments)
        seg = segments{k};
        p1 = seg.point1; p2 = seg.point2;
        plot([p1(1), p2(1)], [p1(2), p2(2)], 'Color', color_char, 'LineWidth', 2);
        
        tx = p1(1) + (p2(1) - p1(1)) / 3;
        ty = p1(2) + (p2(2) - p1(2)) / 3;
        dx = p2(1) - p1(1); dy = p2(2) - p1(2);
        len = sqrt(dx^2 + dy^2);
        
        if len > 0
            nx = -dy / len; ny = dx / len;
            text_x = tx + nx * offset_dist;
            text_y = ty + ny * offset_dist;
        else
            text_x = tx; text_y = ty;
        end
        
        label_str = sprintf('%s_{%d}', prefix, k);
        text(text_x, text_y, label_str, 'Interpreter', 'tex', 'Color', 'k', ...
            'FontSize', 24, 'FontName', 'Times New Roman', 'FontWeight', 'bold', ...
            'HorizontalAlignment', 'center');
    end
end

% --- HELPER: Plotting Cell Arrays (Original) ---
function plot_helper(segments, color_char)
    for k = 1:length(segments)
        seg = segments{k}; 
        clean_color = color_char(1); 
        plot([seg.point1(1), seg.point2(1)], [seg.point1(2), seg.point2(2)], ...
            'Color', clean_color, 'LineStyle', '--', 'LineWidth', 1.5);
    end
end

% --- HELPER: INTERACTIVE LOOP (Original) ---
function [v_segments, l_segments, h_segments] = manual_selection_loop(IMG)
    v_segments = {}; l_segments = {}; h_segments = {};
    h_v = []; h_l = []; h_h = [];
    fig = figure('Name', 'Manual Feature Selection');
    imshow(IMG); hold on;
    state = 1; 
    titles = {'Step 1: VERTICAL', 'Step 2: LONGITUDINAL', 'Step 3: HORIZONTAL'};
    colors = {'b', 'g', 'w'};
    while state >= 1 && state <= 3
        title(titles{state});
        [x1, y1, btn] = ginput(1);
        if isempty(x1) || btn == 13, state = state + 1; continue; end
        if btn == 8 || btn == 127
            if state == 1 && ~isempty(v_segments)
                delete(h_v(end)); h_v(end) = []; v_segments(end) = [];
            elseif state == 2
                if isempty(l_segments), state = 1; else, delete(h_l(end)); h_l(end) = []; l_segments(end) = []; end
            elseif state == 3
                if isempty(h_segments), state = 2; else, delete(h_h(end)); h_h(end) = []; h_segments(end) = []; end
            end
            continue;
        end
        h_temp = plot(x1, y1, 'x', 'Color', colors{state});
        [x2, y2, btn2] = ginput(1);
        delete(h_temp);
        if isempty(x2) || btn2 == 8 || btn2 == 127 || btn2 == 13, continue; end
        h_line = plot([x1, x2], [y1, y2], 'Color', colors{state}, 'LineWidth', 2, 'Marker', 'x');
        new_seg.point1 = [x1, y1]; new_seg.point2 = [x2, y2];
        if state == 1, v_segments{end+1} = new_seg; h_v(end+1) = h_line;
        elseif state == 2, l_segments{end+1} = new_seg; h_l(end+1) = h_line;
        elseif state == 3, h_segments{end+1} = new_seg; h_h(end+1) = h_line;
        end
    end
    close(fig);
end