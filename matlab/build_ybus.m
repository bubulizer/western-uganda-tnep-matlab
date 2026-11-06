function Y = build_ybus(nb, branch)
%BUILD_YBUS Positive-sequence nodal admittance matrix.
Y = complex(zeros(nb));
for k = 1:height(branch)
    if branch.status(k) == 0, continue; end
    i = branch.from_bus(k); j = branch.to_bus(k);
    y = 1/complex(branch.r_pu(k), branch.x_pu(k));
    ysh = 1i*branch.b_pu(k)/2;
    Y(i,i) = Y(i,i) + y + ysh;
    Y(j,j) = Y(j,j) + y + ysh;
    Y(i,j) = Y(i,j) - y;
    Y(j,i) = Y(j,i) - y;
end
end

