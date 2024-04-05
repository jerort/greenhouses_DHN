function [table] = json2table(json,field)

names = fieldnames(eval(strcat('json.features(1).',field)));
table = {};
for i=1:length(names)
    table(:,i) = cellfun(@(x)...
        getfield(x,names{i}),eval(strcat('{json.features(:).',field,'}')),...
        'UniformOutput',false);
end
table = cell2table(table,"VariableNames",names);

end