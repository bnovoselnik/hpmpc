% compile the C code
mex HPMPC_ip_hard.c -lhpmpc %-L. HPMPC.a

% import cool graphic toolkit if in octave
if is_octave()
	graphics_toolkit('gnuplot')
end



% test problem

nx = 12;			% number of states
nu = 5;				% number of inputs (controls)
N = 30;				% horizon length
if 1
	nb  = nu+nx;		% number of two-sided box constraints
	ng  = 0;         % number of two-sided general constraints
	ngN = nx;         % number of two-sided general constraints on last stage
else
	if 0
		nb  = 0;
		ng  = nu+nx;
		ngN = nu+nx;
	else
		nb  = nu;
		ng  = nx;
		ngN = nx;
	end
end

nbu = min(nb, nu);

Ts = 0.5; % sampling time

Ac = [zeros(nx/2), eye(nx/2); diag(-2*ones(nx/2,1))+diag(ones(nx/2-1,1),-1)+diag(ones(nx/2-1,1),1), zeros(nx/2) ];
Bc = [zeros(nx/2,nu); eye(nu); zeros(nx/2-nu, nu)];

M = expm([Ts*Ac, Ts*Bc; zeros(nu, 2*nx/2+nu)]);

% dynamica system
A = M(1:nx,1:nx);
B = M(1:nx,nx+1:end);
b = 0.0*ones(nx,1);
x0 = zeros(nx, 1);
x0(1) = 3.5;
x0(2) = 3.5;
if nx==4
	x0 = [5 10 15 20]';
end
AA = repmat(A, 1, N);
BB = repmat(B, 1, N);
%AA = repmat(A', 1, N);
%BB = repmat(B', 1, N);
bb = repmat(b, 1, N);

% cost function
Q = eye(nx);
Qf = Q;
R = 2*eye(nu);
S = zeros(nx, nu);
q = zeros(nx,1);
q = 1*Q*[ones(nx/2,1); zeros(nx/2,1)];
qf = q;
r = zeros(nu,1);
r = 1*R*ones(nu,1);
QQ = repmat(Q, 1, N);
SS = repmat(S, 1, N);
RR = repmat(R, 1, N);
qq = repmat(q, 1, N);
rr = repmat(r, 1, N);

% general constraints
C  = zeros(ng, nx);
D  = zeros(ng, nu);
CN = zeros(ngN, nx);
if(ng>0)
	if(nb==0)
		for ii=1:min(nu,ng)
			D(ii,ii) = 1.0;
		end
		for ii=min(nu,ng)+1:ng
			C(ii,ii-nu) = 1.0;
		end
	else
		for ii=1:ng
			C(ii,ii) = 1.0;
		end
	end
end
if(ngN>0)
	for ii=1:ngN
		CN(ii,ii) = 1.0;
	end
end
CC = [zeros(ng,nx), repmat(C, 1, N-1)];
DD = [repmat(D, 1, N)];
%CC = [zeros(nx,ng), repmat(C', 1, N)];
%DD = [repmat(D', 1, N), zeros(nu,ng)];

% box constraints
lb = zeros(nb,1);
ub = zeros(nb,1);
%db(1:2*nu) = -1.5;
for ii=1:nbu
	lb(ii) = -2.5; % lower bound
	ub(ii) = -0.1; % - upper bound
end
for ii=nbu+1:nb
	lb(ii) = -10;
	ub(ii) =  10;
end
llb = repmat(lb, 1, N+1);
uub = repmat(ub, 1, N+1);
% general constraints
lg = zeros(ng,1);
ug = zeros(ng,1);
if(ng>0)
	if(nb==0)
		for ii=1:min(nu,ng)
			lg(ii) = -2.5; % lower bound
			ug(ii) = -0.1; % - upper bound
		end
		for ii=min(nu,ng)+1:ng
			lg(ii) = -10;
			ug(ii) =  10;
		end
	else
		for ii=1:ng
			lg(ii) = -10;
			ug(ii) =  10;
		end
	end
end
%db(2*nu+1:end) = -4;
llg = repmat(lg, 1, N);
uug = repmat(ug, 1, N);
% general constraints last stage
lgN = zeros(ngN,1);
ugN = zeros(ngN,1);
if(ngN>0)
	if(nb==0)
%		for ii=1:min(nu,ng)
%			lg(ii) = -2.5; % lower bound
%			ug(ii) = -0.1; % - upper bound
%		end
		for ii=min(nu,ng)+1:ng
			lgN(ii) =   0;
			ugN(ii) =   0;
		end
	else
		for ii=1:ng
			lgN(ii) =   0;
			ugN(ii) =   0;
		end
	end
end
%if(ng>0)
%	if(nb==0)
%		uub(1:min(nu,ng),N+1) =  0.0;
%	end
%end

% initial guess for states and inputs
x = zeros(nx, N+1); %x(:,1) = x0; % initial condition
%u = -1*ones(nu, N);
u = zeros(nu, N);
%pi = zeros(nx, N+1);

mu0 = 2;        % max element in cost function as estimate of max multiplier
kk = -1;		% actual number of performed iterations
k_max = 20;		% maximim number of iterations
tol = 1e-8;		% tolerance in the duality measure
infos = zeros(5, k_max);
compute_res = 1;
inf_norm_res = zeros(1, 4);
compute_mult = 1;
mult_pi = zeros(nx,N+1);
mult_lam = zeros(2*(nb+ng)*N+2*(nb+ngN),1);
mult_t = zeros(2*(nb+ng)*N+2*(nb+ngN),1);

nrep = 100;

tic
for ii=1:nrep
	HPMPC_ip_hard(kk, k_max, mu0, tol, N, nx, nu, nb, ng, ngN, AA, BB, bb, QQ, Qf, RR, SS, qq, qf, rr, llb, uub, CC, DD, llg, uug, CN, lgN, ugN, x, u, infos, compute_res, inf_norm_res, compute_mult, mult_pi, mult_lam, mult_t);
end
solution_time = toc/nrep

kk
infos(:,1:kk)'
inf_norm_res

u
x


figure()
plot([0:N], x(:,:))
title('states')
xlabel('N')

figure()
plot([1:N], u(:,:))
title('controls')
xlabel('N')


