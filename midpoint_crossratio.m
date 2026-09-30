function M = midpoint_crossratio(A, B, V)
    % MIDPOINT_CROSSRATIO Calcola il punto medio proiettivo tra A e B.
    % Input: Coordinate omogenee [x; y; w] (3x1)
    
    % 1. Gestione robusta input (trasforma in colonne se necessario)
    A = A(:); B = B(:); V = V(:);

    % 2. Gestione Caso Affine (V all'infinito o molto lontano)
    % Se V(3) è zero, le linee sono parallele -> Punto medio Euclideo standard
    if abs(V(3)) < 1e-9
        a_eucl = A(1:2) / A(3);
        b_eucl = B(1:2) / B(3);
        M = (a_eucl + b_eucl) / 2;
        return;
    end

    % 3. Converti in Cartesiane per il calcolo delle distanze
    a = A(1:2) / A(3);
    b = B(1:2) / B(3);
    v = V(1:2) / V(3);

    % 4. Calcolo delle distanze da V
    % Calcoliamo quanto sono distanti gli estremi dal punto di fuga
    d_AV = norm(a - v);
    d_BV = norm(b - v);

    % 5. Calcolo del Peso (Ratio)
    % La teoria proiettiva dice che M divide AB con un peso che dipende
    % dal rapporto delle distanze dal punto di fuga.
    % rho = dist(A,V) / dist(B,V)
    rho = d_AV / d_BV;

    % 6. Calcolo Coordinate M (Media Pesata)
    % Formula derivata dal Cross-Ratio armonico (-1):
    % M = (A + rho * B) / (1 + rho)
    %
    % Perché funziona:
    % - Se V è lontanissimo (d_AV ~= d_BV), rho = 1 -> M = (A+B)/2 (Euclideo)
    % - Se V è vicino a B (d_BV piccolo), rho è grande -> M viene "attratto" da B
    %   (corretto, perché in prospettiva le cose lontane si schiacciano verso V)
    
    M = (a + rho * b) / (1 + rho);
end