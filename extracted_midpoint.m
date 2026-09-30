function midpoints = extracted_midpoint()
% EXTRACTED_MIDPOINT Recupera l'ultimo set di midpoints salvato nella cartella 'mat'.
%
%   Uso:
%       midpoints = extracted_midpoint();
%
%   Questa funzione cerca il file 'midpoints_backup.mat' all'interno della
%   sottocartella 'mat'.

    % Costruisce il percorso completo: cartella 'mat' + nome file
    filepath = fullfile('mat', 'midpoints_backup.mat');
    
    if exist(filepath, 'file')
        % Carica il file dal percorso specificato
        data = load(filepath);
        if isfield(data, 'A')
            midpoints = data.A;
            fprintf('Midpoints recuperati con successo dalla cartella "mat" (%d punti).\n', size(midpoints, 2));
        else
            error('Il file "%s" esiste ma non contiene la variabile "A".', filepath);
        end
    else
        error(['File non trovato: %s\n' ...
               'Verifica che la cartella "mat" esista e contenga il backup creato da "seleziona_midpoints".'], filepath);
    end
end