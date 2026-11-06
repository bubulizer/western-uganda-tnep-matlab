function result = ac_power_flow(c, branch, opts)
%AC_POWER_FLOW Full nonlinear AC Newton-Raphson power flow.
arguments
    c struct
    branch table
    opts.tolerance (1,1) double = 1e-9
    opts.max_iterations (1,1) double = 40
end
bus = c.bus; nb = height(bus); base = c.baseMVA;
Y = build_ybus(nb, branch);
if ismember('Gs_MW',bus.Properties.VariableNames)
    Y = Y + diag((bus.Gs_MW - 1i*bus.Bs_MVAr)/base);
end
G = real(Y); B = imag(Y);
slack = find(bus.type_code == 3);
pv = find(bus.type_code == 2);
pq = find(bus.type_code == 1);
ang_idx = [pv; pq];
Vm = bus.Vset_pu;
Va = zeros(nb,1);
Pspec = (bus.Pg_MW - bus.Pd_MW)/base;
Qspec = (bus.Qg_MVAr - bus.Qd_MVAr)/base;
converged = false; mismatch = inf;

for iter = 1:opts.max_iterations
    V = Vm .* exp(1i*Va);
    Scalc = V .* conj(Y*V);
    P = real(Scalc); Q = imag(Scalc);
    mis = [Pspec(ang_idx)-P(ang_idx); Qspec(pq)-Q(pq)];
    mismatch = max(abs(mis));
    if mismatch < opts.tolerance
        converged = true; break
    end
    nA = numel(ang_idx); nQ = numel(pq);
    H = zeros(nA,nA); N = zeros(nA,nQ);
    M = zeros(nQ,nA); L = zeros(nQ,nQ);
    for a = 1:nA
        i = ang_idx(a);
        for b = 1:nA
            j = ang_idx(b);
            if i == j
                H(a,b) = -Q(i) - B(i,i)*Vm(i)^2;
            else
                th = Va(i)-Va(j);
                H(a,b) = Vm(i)*Vm(j)*(G(i,j)*sin(th)-B(i,j)*cos(th));
            end
        end
        for b = 1:nQ
            j = pq(b);
            if i == j
                N(a,b) = P(i)/Vm(i) + G(i,i)*Vm(i);
            else
                th = Va(i)-Va(j);
                N(a,b) = Vm(i)*(G(i,j)*cos(th)+B(i,j)*sin(th));
            end
        end
    end
    for a = 1:nQ
        i = pq(a);
        for b = 1:nA
            j = ang_idx(b);
            if i == j
                M(a,b) = P(i) - G(i,i)*Vm(i)^2;
            else
                th = Va(i)-Va(j);
                M(a,b) = -Vm(i)*Vm(j)*(G(i,j)*cos(th)+B(i,j)*sin(th));
            end
        end
        for b = 1:nQ
            j = pq(b);
            if i == j
                L(a,b) = Q(i)/Vm(i) - B(i,i)*Vm(i);
            else
                th = Va(i)-Va(j);
                L(a,b) = Vm(i)*(G(i,j)*sin(th)-B(i,j)*cos(th));
            end
        end
    end
    J = [H N; M L];
    if rcond(J) < 1e-13, break; end
    dx = J\mis;
    Va(ang_idx) = Va(ang_idx) + dx(1:nA);
    Vm(pq) = Vm(pq) + dx(nA+1:end);
    if any(~isfinite(Vm)) || any(Vm < 0.4) || any(Vm > 1.6), break; end
end

V = Vm .* exp(1i*Va);
Sbus = V .* conj(Y*V) * base;
result.converged = converged;
result.iterations = iter;
result.max_mismatch_pu = mismatch;
result.V = V;
result.Vm = abs(V);
result.Va_deg = rad2deg(angle(V));
result.Pinj_MW = real(Sbus);
result.Qinj_MVAr = imag(Sbus);
result.slack_P_MW = real(Sbus(slack)) + bus.Pd_MW(slack);
result.slack_Q_MVAr = imag(Sbus(slack)) + bus.Qd_MVAr(slack);
result.branch = branch_flows(c, branch, V);
result.loss_MW = sum(result.branch.loss_MW);
result.voltage_deviation = sum(abs(result.Vm-1));
result.min_voltage = min(result.Vm);
result.max_voltage = max(result.Vm);
result.max_loading_pct = max(result.branch.loading_pct);
end
