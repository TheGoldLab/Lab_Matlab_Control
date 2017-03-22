reps = 60*10;

[s,r] = unix(sprintf('top -l %d', reps));
s = strfind(r, 'PID')+76;
p = [strfind(r, 'Processes')-2, length(r)];
f = p(2:end);

CPU = nan*ones(50, reps);
CMD = cell(50, reps);

for ii = 1:length(s)
    toks = textscan(r(s(ii):f(ii)), '%s', 'MultipleDelimsAsOne', 1);
    stok = reshape(toks{1}, 11, []);
    CMD(1:size(stok, 2), ii) = stok(2, :);
    cpu = sscanf([stok{3, :}], '%f%%')';
    CPU(1:length(cpu), ii) = cpu;
end

interesting = find(nansum(CPU'));
plot(CPU(interesting, :)')
xlabel('seconds')
ylabel('%CPU')
legend(CMD(interesting,end))