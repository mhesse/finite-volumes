function [A] = build_adv_op(q,c,dt,G,Grid,Param,method)
% author: Marc Hesse
% date: 12 Aug 2016
% Description: Builds the advection matrix containing the upwinded and 
%              limited fluxes given the current fluxes and concentration 
%              field.

% Input
% q = Nf by 1 flux vector on cell faces
% c = N by 1 vector of cell-centered values
% dt = current timestep (scalar)
% G = Nf by N discrete gradient matrix
% Grid = structure containing all pertinent information about the grid.
% Param = structure containing pertinent information about problem.
% method = indicates the flux limiter
%
% Output:
% A = Nf by N matrix contining the upwinded fluxes

% Example call:
% >> Grid.xmin = 0; Grid.xmax = 1; Grid.Nx = 10;
% >> Grid = build_grid(Grid);
% >> [D,G,I] = build_ops(Grid);
% >> Param.dof_out = Grid.dof_xmax;
% >> c = sin(Grid.xc);
% >> q = ones(Grid.Nfx,1);
% >> A = build_adv_op(q,c,.1,G,Grid,Param,'mc');


%% 1st0order Upwind/Godonov fluxes (required for all discretizations)
% Lines 19 to 45 are identical to flux_upwind.m
Nx = Grid.Nx; Ny = Grid.Ny; Nz = Grid.Nz; N = Grid.N;
Nfx = Grid.Nfx; % # of x faces
Nfy = Grid.Nfy; % # of y faces
Nf = length(q);

%% First-order upwind (Godunov) fluxes
A = flux_upwind(q,Grid);

%% Second-order flux correction
if ~strcmp(method,'gd') % If not first order Godunov-scheme
    % Save upwind fluxes at outflow
    Aup = A(Param.dof_out,:);
    
    % Build vector with cell sizes
    if Nx>1  && Ny==1
        dxy = ones(Grid.Nfx,1)*Grid.dx;
    elseif Nx==1 && Ny>1 % 1D
        dxy = ones(Grid.Nfy,1)*Grid.dy;
    else
        dxy = [ones(Grid.Nfx,1)*Grid.dx;ones(Grid.Nfy,1)*Grid.dy];
    end
    % Compute smoothness indicator
    theta = smoothness(dxy.*(G*c),q,Grid);
    
    % Compute flux limiter
    phi_lim = comp_limiter(theta,method);
    
    %% 2nd-order Lax-Wendroff flux
    A = A + spdiags(dxy.*abs(q)/2,0,Nf,Nf)*(speye(Nf)-spdiags(dt*abs(q)./dxy,0,Nf,Nf))*spdiags(phi_lim,0,Nf,Nf)*G;
    
    % Reduce flux to upwind at outflow boundaries
    A(Param.dof_out,:) = Aup;
end
