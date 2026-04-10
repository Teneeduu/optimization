%------------------------------------------------------%
% 用于《计算智能》课程
% 算法：GA-PSO 混合算法
% 函数库：Hedar
% 注意：测试前先将Hedar_test_set文件夹加入搜索路径
%------------------------------------------------------%
function [H, N] = test_Hedar()
% H : 算法求解Hedar库的测试数据 (maxnfev × maxrun × maxnp)
% N : 问题维数向量

global fvals nfev nprob maxnfev  % 用于保存函数值历史和计算次数、问题编号

maxnfev = 5000;      % 最大函数值计算次数            
nfev = 0;            % 函数值计算次数初值
maxnp = 68;          % 测试函数个数
maxrun = 30;         % 运行多少次算法

% 问题维数向量
tt = [2, 5, 10, 20];
N = [tt, 2*ones(1,6), 4, tt, 2, 2, tt, 3, 6, 2, tt, 2, 2, 5, 10, 4, 4, 12, 24, 48, ...
     4, tt, tt, tt, 4, 4, 4, 2, tt, tt, 6, 10, tt];

% 用于存储测试结果
Htemp50 = zeros(maxnfev, maxrun, maxnp); 

%========================= 开始测试 ========================
for nprob = 1:maxnp
    fprintf('Begin to test the %3d th problem\n', nprob);
    
    % 获取问题信息
    dim = N(nprob);
    [~, bounds, ~] = getoptions(nprob);
    
    % GA-PSO 参数设置
    popsize = 30;       % 种群大小
    pc = 0.7;           % 交叉概率
    pm = 0.1;           % 变异概率
    c1 = 1.49445;       % PSO个体学习因子
    c2 = 1.49445;       % PSO群体学习因子
    w = 0.5;            % 惯性权重
    
    % 边界转换
    lb = bounds(:, 1)';
    ub = bounds(:, 2)';
    Vmax = 0.2 * (ub - lb);
    Vmin = -Vmax;
    
    % 运行 maxrun 次
    for r = 1:maxrun
        % 设定随机数流，保证结果可重复
        s = RandStream.create('mt19937ar', 'seed', 2015 + r);
        RandStream.setGlobalStream(s);
        
        % 重置全局变量
        global nfev fvals;
        nfev = 0;
        fvals = [];
        
        % ========== GA-PSO 算法主体 ==========
        % 初始化种群
        pop = repmat(lb, popsize, 1) + rand(popsize, dim) .* repmat(ub - lb, popsize, 1);
        V = repmat(Vmin, popsize, 1) + rand(popsize, dim) .* repmat(Vmax - Vmin, popsize, 1);
        
        % 评估初始种群
        fitness = zeros(popsize, 1);
        for i = 1:popsize
            fitness(i) = cal_fun(pop(i, :), nprob);
            if nfev >= maxnfev, break; end
        end
        
        % 初始化最优
        [best_fitness, best_idx] = min(fitness);
        zbest = pop(best_idx, :);
        gbest = pop;
        fitness_gbest = fitness;
        
        % 主循环
        while nfev < maxnfev
            % --- PSO 更新 ---
            for i = 1:popsize
                if nfev >= maxnfev, break; end
                
                V(i, :) = w * V(i, :) + ...
                          c1 * rand(1, dim) .* (gbest(i, :) - pop(i, :)) + ...
                          c2 * rand(1, dim) .* (zbest - pop(i, :));
                V(i, :) = max(min(V(i, :), Vmax), Vmin);
                
                pop(i, :) = pop(i, :) + V(i, :);
                pop(i, :) = max(min(pop(i, :), ub), lb);
            end
            
            % --- GA 交叉 ---
            for i = 1:2:popsize-1
                if nfev >= maxnfev, break; end
                
                if rand < pc
                    alpha = rand;
                    pos = randi(dim);
                    
                    temp = pop(i, pos);
                    pop(i, pos) = alpha * pop(i+1, pos) + (1-alpha) * temp;
                    pop(i+1, pos) = alpha * temp + (1-alpha) * pop(i+1, pos);
                    
                    pop(i, pos) = max(min(pop(i, pos), ub(pos)), lb(pos));
                    pop(i+1, pos) = max(min(pop(i+1, pos), ub(pos)), lb(pos));
                end
            end
            
            % --- GA 变异 ---
            for i = 1:popsize
                if nfev >= maxnfev, break; end
                
                if rand < pm
                    pos = randi(dim);
                    if rand < 0.5
                        delta = (pop(i, pos) - lb(pos)) * rand;
                        pop(i, pos) = pop(i, pos) - delta;
                    else
                        delta = (ub(pos) - pop(i, pos)) * rand;
                        pop(i, pos) = pop(i, pos) + delta;
                    end
                    pop(i, pos) = max(min(pop(i, pos), ub(pos)), lb(pos));
                end
            end
            
            % --- 评估新一代 ---
            for i = 1:popsize
                if nfev >= maxnfev, break; end
                
                fitness(i) = cal_fun(pop(i, :), nprob);
                
                if fitness(i) < fitness_gbest(i)
                    gbest(i, :) = pop(i, :);
                    fitness_gbest(i) = fitness(i);
                end
                
                if fitness(i) < best_fitness
                    zbest = pop(i, :);
                    best_fitness = fitness(i);
                end
            end
        end
        % ========== 算法结束 ==========
        
        % 数据处理
        his = fvals; 
        fvals = []; 
        nfev = 0;
        His = modifyhis(his, maxnfev); 
        Htemp50(:, r, nprob) = His;
        
        if mod(r, 5) == 0
            fprintf('  Run %2d completed, best = %.6f\n', r, best_fitness);
        end
    end
    
    fprintf('Problem %3d finished.\n\n', nprob);
end

% 保存测试结果
H = Htemp50;
clear global

fprintf('========================================\n');
fprintf('All 68 problems tested!\n');
fprintf('========================================\n');

end

% ==================== 辅助函数 ====================

function f = cal_fun(x, nprob)
% 计算函数值并记录历史
global nfev fvals

% 获取问题信息
[Problem, ~, ~] = getoptions(nprob);
func_name = Problem.f;

% 调用目标函数
f = eval_function(func_name, x);

% 记录
nfev = nfev + 1;
if isempty(fvals)
    fvals = f;
else
    fvals = [fvals; min(f, fvals(end))];
end
end

function y = eval_function(func_name, x)
% 调用Hedar函数库
switch lower(func_name)
    case 'ackley'
        y = ackley(x);
    case 'beale'
        y = beale(x);
    case 'boh1'
        y = bh1(x);
    case 'boh2'
        y = bh2(x);
    case 'boh3'
        y = bh3(x);
    case 'booth'
        y = booth(x);
    case 'branin'
        y = branin(x);
    case 'colville'
        y = colville(x);
    case 'dp'
        y = dp(x);
    case 'easom'
        y = easom(x);
    case 'gold'
        y = gold(x);
    case 'griewank'
        y = griewank(x);
    case 'hart3'
        y = hart3(x);
    case 'hart6'
        y = hart6(x);
    case 'hump'
        y = hump(x);
    case 'levy'
        y = levy(x);
    case 'matyas'
        y = matyas(x);
    case 'mich'
        y = mich(x);
    case 'perm'
        y = perm(x);
    case 'powell'
        y = powell(x);
    case 'powersum'
        y = powersum(x);
    case 'rast'
        y = rast(x);
    case 'rosen'
        y = rosen(x);
    case 'schw'
        y = schw(x);
    case 'shekel5'
        y = shekel(x, 5);
    case 'shekel7'
        y = shekel(x, 7);
    case 'shekel10'
        y = shekel(x, 10);
    case 'shub'
        y = shub(x);
    case 'sphere'
        y = sum(x.^2);
    case 'sum2'
        y = sum2(x);
    case 'trid'
        y = trid(x);
    case 'zakh'
        y = zakh(x);
    otherwise
        error('未知函数: %s', func_name);
end
end

function [Problem, bounds, options] = getoptions(nprob)
options.testflag = 1;
options.showits = 0;
options.ep = 0;

switch nprob
    case 1
        options.globalmin = 0;
        Problem.f = 'ackley';
        bounds = [-15*ones(2,1) 30*ones(2,1)];
    case 2
        options.globalmin = 0;
        Problem.f = 'ackley';
        bounds = [-15*ones(5,1) 30*ones(5,1)];
    case 3
        options.globalmin = 0;
        Problem.f = 'ackley';
        bounds = [-15*ones(10,1) 30*ones(10,1)];
    case 4
        options.globalmin = 0;
        Problem.f = 'ackley';
        bounds = [-15*ones(20,1) 30*ones(20,1)];
    case 5
        options.globalmin = 0;
        Problem.f = 'beale';
        bounds = [-4.5*ones(2,1) 4.5*ones(2,1)];
    case 6
        options.globalmin = 0;
        Problem.f = 'boh1';
        bounds = [-80*ones(2,1) 125*ones(2,1)];
    case 7
        options.globalmin = 0;
        Problem.f = 'boh2';
        bounds = [-80*ones(2,1) 125*ones(2,1)];
    case 8
        options.globalmin = 0;
        Problem.f = 'boh3';
        bounds = [-80*ones(2,1) 125*ones(2,1)];
    case 9
        options.globalmin = 0;
        Problem.f = 'booth';
        bounds = [-10*ones(2,1) 10*ones(2,1)];
    case 10
        options.globalmin = 0.397887357729739;
        Problem.f = 'branin';
        bounds = [-5 10; 0 15];
    case 11
        options.globalmin = 0;
        Problem.f = 'colville';
        bounds = [-8*ones(4,1) 12.5*ones(4,1)];
    case 12
        options.globalmin = 0;
        Problem.f = 'dp';
        bounds = [-10*ones(2,1) 10*ones(2,1)];
    case 13
        options.globalmin = 0;
        Problem.f = 'dp';
        bounds = [-10*ones(5,1) 10*ones(5,1)];
    case 14
        options.globalmin = 0;
        Problem.f = 'dp';
        bounds = [-10*ones(10,1) 10*ones(10,1)];
    case 15
        options.globalmin = 0;
        Problem.f = 'dp';
        bounds = [-10*ones(20,1) 10*ones(20,1)];
    case 16
        options.globalmin = -1;
        Problem.f = 'easom';
        bounds = [-100*ones(2,1) 100*ones(2,1)];
    case 17
        bounds = [-2 2; -2 2];
        options.globalmin = 3;
        Problem.f = 'gold';
    case 18
        options.globalmin = 0;
        Problem.f = 'griewank';
        bounds = [-480*ones(2,1) 750*ones(2,1)];
    case 19
        options.globalmin = 0;
        Problem.f = 'griewank';
        bounds = [-480*ones(5,1) 750*ones(5,1)];
    case 20
        options.globalmin = 0;
        Problem.f = 'griewank';
        bounds = [-480*ones(10,1) 750*ones(10,1)];
    case 21
        options.globalmin = 0;
        Problem.f = 'griewank';
        bounds = [-480*ones(20,1) 750*ones(20,1)];
    case 22
        options.globalmin = -3.86278214782076;
        Problem.f = 'hart3';
        bounds = [0 1; 0 1; 0 1];
    case 23
        options.globalmin = -3.32236801141551;
        Problem.f = 'hart6';
        bounds = [0 1; 0 1; 0 1; 0 1; 0 1; 0 1];
    case 24
        options.globalmin = -1.0316284535;
        Problem.f = 'hump';
        bounds = [-5 5; -5 5];
    case 25
        options.globalmin = 0;
        Problem.f = 'levy';
        bounds = [-10*ones(2,1) 10*ones(2,1)];
    case 26
        options.globalmin = 0;
        Problem.f = 'levy';
        bounds = [-10*ones(5,1) 10*ones(5,1)];
    case 27
        options.globalmin = 0;
        Problem.f = 'levy';
        bounds = [-10*ones(10,1) 10*ones(10,1)];
    case 28
        options.globalmin = 0;
        Problem.f = 'levy';
        bounds = [-10*ones(20,1) 10*ones(20,1)];
    case 29
        options.globalmin = 0;
        Problem.f = 'matyas';
        bounds = [-8*ones(2,1) 12.5*ones(2,1)];
    case 30
        options.globalmin = -1.80130341008983;
        Problem.f = 'mich';
        bounds = [0*ones(2,1) pi*ones(2,1)];
    case 31
        options.globalmin = -4.687658179;
        Problem.f = 'mich';
        bounds = [0*ones(5,1) pi*ones(5,1)];
    case 32
        options.globalmin = -9.66015;
        Problem.f = 'mich';
        bounds = [0*ones(10,1) pi*ones(10,1)];
    case 33
        options.globalmin = 0;
        Problem.f = 'perm';
        bounds = [-4*ones(4,1) 4*ones(4,1)];
    case 34
        options.globalmin = 0;
        Problem.f = 'powell';
        bounds = [-4*ones(4,1) 5*ones(4,1)];
    case 35
        options.globalmin = 0;
        Problem.f = 'powell';
        bounds = [-4*ones(12,1) 5*ones(12,1)];
    case 36
        options.globalmin = 0;
        Problem.f = 'powell';
        bounds = [-4*ones(24,1) 5*ones(24,1)];
    case 37
        options.globalmin = 0;
        Problem.f = 'powell';
        bounds = [-4*ones(48,1) 5*ones(48,1)];
    case 38
        options.globalmin = 0;
        Problem.f = 'powersum';
        bounds = [0*ones(4,1) 5*ones(4,1)];
    case 39
        options.globalmin = 0;
        Problem.f = 'rast';
        bounds = [-4.1*ones(2,1) 6.4*ones(2,1)];
    case 40
        options.globalmin = 0;
        Problem.f = 'rast';
        bounds = [-4.1*ones(5,1) 6.4*ones(5,1)];
    case 41
        options.globalmin = 0;
        Problem.f = 'rast';
        bounds = [-4.1*ones(10,1) 6.4*ones(10,1)];
    case 42
        options.globalmin = 0;
        Problem.f = 'rast';
        bounds = [-4.1*ones(20,1) 6.4*ones(20,1)];
    case 43
        options.globalmin = 0;
        Problem.f = 'rosen';
        bounds = [-5*ones(2,1) 10*ones(2,1)];
    case 44
        options.globalmin = 0;
        Problem.f = 'rosen';
        bounds = [-5*ones(5,1) 10*ones(5,1)];
    case 45
        options.globalmin = 0;
        Problem.f = 'rosen';
        bounds = [-5*ones(10,1) 10*ones(10,1)];
    case 46
        options.globalmin = 0;
        Problem.f = 'rosen';
        bounds = [-5*ones(20,1) 10*ones(20,1)];
    case 47
        options.globalmin = 0;
        Problem.f = 'schw';
        bounds = [-500*ones(2,1) 500*ones(2,1)];
    case 48
        options.globalmin = 0;
        Problem.f = 'schw';
        bounds = [-500*ones(5,1) 500*ones(5,1)];
    case 49
        options.globalmin = 0;
        Problem.f = 'schw';
        bounds = [-500*ones(10,1) 500*ones(10,1)];
    case 50
        options.globalmin = 0;
        Problem.f = 'schw';
        bounds = [-500*ones(20,1) 500*ones(20,1)];
    case 51
        options.globalmin = -10.1531996790582;
        Problem.f = 'shekel5';
        bounds = [0 10; 0 10; 0 10; 0 10];
    case 52
        options.globalmin = -10.4029405668187;
        Problem.f = 'shekel7';
        bounds = [0 10; 0 10; 0 10; 0 10];
    case 53
        options.globalmin = -10.5364098166920;
        Problem.f = 'shekel10';
        bounds = [0 10; 0 10; 0 10; 0 10];
    case 54
        options.globalmin = -186.730908831024;
        Problem.f = 'shub';
        bounds = [-10 10; -10 10];
    case 55
        options.globalmin = 0;
        Problem.f = 'sphere';
        bounds = [-4.1*ones(2,1) 6.4*ones(2,1)];
    case 56
        options.globalmin = 0;
        Problem.f = 'sphere';
        bounds = [-4.1*ones(5,1) 6.4*ones(5,1)];
    case 57
        options.globalmin = 0;
        Problem.f = 'sphere';
        bounds = [-4.1*ones(10,1) 6.4*ones(10,1)];
    case 58
        options.globalmin = 0;
        Problem.f = 'sphere';
        bounds = [-4.1*ones(20,1) 6.4*ones(20,1)];
    case 59
        options.globalmin = 0;
        Problem.f = 'sum2';
        bounds = [-8*ones(2,1) 12.5*ones(2,1)];
    case 60
        options.globalmin = 0;
        Problem.f = 'sum2';
        bounds = [-8*ones(5,1) 12.5*ones(5,1)];
    case 61
        options.globalmin = 0;
        Problem.f = 'sum2';
        bounds = [-8*ones(10,1) 12.5*ones(10,1)];
    case 62
        options.globalmin = 0;
        Problem.f = 'sum2';
        bounds = [-8*ones(20,1) 12.5*ones(20,1)];
    case 63
        options.globalmin = -50;
        Problem.f = 'trid';
        bounds = [-36*ones(6,1) 36*ones(6,1)];
    case 64
        options.globalmin = -200;
        Problem.f = 'trid';
        bounds = [-100*ones(10,1) 100*ones(10,1)];
    case 65
        options.globalmin = 0;
        Problem.f = 'zakh';
        bounds = [-5*ones(2,1) 10*ones(2,1)];
    case 66
        options.globalmin = 0;
        Problem.f = 'zakh';
        bounds = [-5*ones(5,1) 10*ones(5,1)];
    case 67
        options.globalmin = 0;
        Problem.f = 'zakh';
        bounds = [-5*ones(10,1) 10*ones(10,1)];
    case 68
        options.globalmin = 0;
        Problem.f = 'zakh';
        bounds = [-5*ones(20,1) 10*ones(20,1)];
end
end

function His = modifyhis(his, maxnfev)
His = zeros(maxnfev, 1);
His(1) = his(1);
for j = 2:maxnfev
    if j > size(his, 1)
        His(j) = his(size(his, 1));
    elseif his(j) > His(j-1)
        His(j) = His(j-1);
    else
        His(j) = his(j);
    end
end
end