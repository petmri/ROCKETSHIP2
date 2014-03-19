function plot_dce_curve(plot_data)
fit_parameters = plot_data.fit_parameters;

% fit_parameters = fitting_results(voi,:);
if strcmp(plot_data.model_name,'aif') || strcmp(plot_data.model_name,'tofts')
    fit_curve = model_tofts_cfit(fit_parameters(1),fit_parameters(2),plot_data.Cp,plot_data.timer);
    fit_curve_low = model_tofts_cfit(fit_parameters(4),fit_parameters(6),plot_data.Cp,plot_data.timer);
    fit_curve_high = model_tofts_cfit(fit_parameters(5),fit_parameters(7),plot_data.Cp,plot_data.timer);
elseif strcmp(plot_data.model_name,'aif_vp') || strcmp(plot_data.model_name,'ex_tofts')
    fit_curve = model_extended_tofts_cfit(fit_parameters(1),fit_parameters(2),fit_parameters(3),plot_data.Cp,plot_data.timer);
    fit_curve_low = model_extended_tofts_cfit(fit_parameters(5),fit_parameters(7),fit_parameters(9),plot_data.Cp,plot_data.timer);
    fit_curve_high = model_extended_tofts_cfit(fit_parameters(6),fit_parameters(8),fit_parameters(10),plot_data.Cp,plot_data.timer);
elseif strcmp(plot_data.model_name,'fxr')
    fit_curve = model_fxr_cfit(fit_parameters(1),fit_parameters(2),fit_parameters(3),plot_data.Cp,plot_data.timer,plot_data.R1o,plot_data.R1i,plot_data.r1,plot_data.fw);
    fit_curve_low = model_fxr_cfit(fit_parameters(5),fit_parameters(7),fit_parameters(9),plot_data.Cp,plot_data.timer,plot_data.R1o,plot_data.R1i,plot_data.r1,plot_data.fw);
    fit_curve_high = model_fxr_cfit(fit_parameters(6),fit_parameters(8),fit_parameters(10),plot_data.Cp,plot_data.timer,plot_data.R1o,plot_data.R1i,plot_data.r1,plot_data.fw);
elseif strcmp(plot_data.model_name,'patlak')
    fit_curve = model_patlak_cfit(fit_parameters(1),fit_parameters(2),plot_data.Cp,plot_data.timer);
    fit_curve_low = model_patlak_cfit(fit_parameters(4),fit_parameters(6),plot_data.Cp,plot_data.timer);
    fit_curve_high = model_patlak_cfit(fit_parameters(5),fit_parameters(7),plot_data.Cp,plot_data.timer);
elseif strcmp(plot_data.model_name,'nested')
    if fit_parameters(1)==0 && fit_parameters(2)==0 && fit_parameters(3)==0 
        % Model 0
        fit_curve = zeros(size(plot_data.Cp));
        fit_curve_low = zeros(size(plot_data.Cp));
        fit_curve_high = zeros(size(plot_data.Cp));
    elseif fit_parameters(1)==0 && fit_parameters(2)==0
        % Model vp
        fit_curve = model_vp_cfit(fit_parameters(3),plot_data.Cp,plot_data.timer);
        fit_curve_low = model_vp_cfit(fit_parameters(9),plot_data.Cp,plot_data.timer);
        fit_curve_high = model_vp_cfit(fit_parameters(10),plot_data.Cp,plot_data.timer);
    elseif fit_parameters(2)==0
        % Model Patlak
        fit_curve = model_patlak_cfit(fit_parameters(1),fit_parameters(3),plot_data.Cp,plot_data.timer);
        fit_curve_low = model_patlak_cfit(fit_parameters(5),fit_parameters(9),plot_data.Cp,plot_data.timer);
        fit_curve_high = model_patlak_cfit(fit_parameters(6),fit_parameters(10),plot_data.Cp,plot_data.timer);
    else
        % Model Extended Tofts
        fit_curve = model_extended_tofts_cfit(fit_parameters(1),fit_parameters(2),fit_parameters(3),plot_data.Cp,plot_data.timer);
        fit_curve_low = model_extended_tofts_cfit(fit_parameters(5),fit_parameters(7),fit_parameters(9),plot_data.Cp,plot_data.timer);
        fit_curve_high = model_extended_tofts_cfit(fit_parameters(6),fit_parameters(8),fit_parameters(10),plot_data.Cp,plot_data.timer);
    end
else
    disp('Analysis not availble for this model');
    return
end

if plot_data.show_original
    p_original = plot(plot_data.timer,plot_data.Ct_original);
    set(p_original(1),'Color',[0.7 0.7 0.8]);
    hold on
end

p = plot(plot_data.timer,plot_data.Ct,...
    plot_data.timer,fit_curve(:,1));
% 		set(p(1),'Marker','.','MarkerSize',4,'LineStyle','none');
set(p(1),'Color',[0.6 0.6 0.7]);
set(p(2),'Color','b');
if plot_data.show_original
    set(p(1),'Color','k');
end
if plot_data.show_ci
    hold on
    p_ci = plot(plot_data.timer,fit_curve_low(:,1),...
        plot_data.timer,fit_curve_high(:,1));
    set(p_ci(1),'Color','k');
    set(p_ci(2),'Color','k');
end
hold off


plot_limits = axis;
% Estimate Error
if strcmp(plot_data.model_name,'aif') || strcmp(plot_data.model_name,'tofts')
    ktrans_error = mean([abs(fit_parameters(1)-fit_parameters(4)) abs(fit_parameters(1)-fit_parameters(5))]);
    ve_error = mean([abs(fit_parameters(2)-fit_parameters(6)) abs(fit_parameters(2)-fit_parameters(7))]);
    plot_str(1) = {[' K_{trans} = ' num2str(fit_parameters(1),2) '�' num2str(ktrans_error,2)]};
    plot_str(2) = {[' V_e = ' num2str(fit_parameters(2),2) '�' num2str(ve_error,2)]};
    plot_str(3) = {[' residual = ' num2str(fit_parameters(3))]};
elseif strcmp(plot_data.model_name,'aif_vp') || strcmp(plot_data.model_name,'ex_tofts') || strcmp(plot_data.model_name,'nested')
    ktrans_error = mean([abs(fit_parameters(1)-fit_parameters(5)) abs(fit_parameters(1)-fit_parameters(6))]);
    ve_error = mean([abs(fit_parameters(2)-fit_parameters(7)) abs(fit_parameters(2)-fit_parameters(8))]);
    vp_error = mean([abs(fit_parameters(3)-fit_parameters(9)) abs(fit_parameters(3)-fit_parameters(10))]);
    plot_str(1) = {[' K_{trans} = ' num2str(fit_parameters(1),2) '�' num2str(ktrans_error,2)]};
    plot_str(2) = {[' V_e = ' num2str(fit_parameters(2),2) '�' num2str(ve_error,2)]};
    plot_str(3) = {[' V_p = ' num2str(fit_parameters(3),2) '�' num2str(vp_error,2)]};
    plot_str(4) = {[' residual = ' num2str(fit_parameters(4))]};
elseif strcmp(plot_data.model_name,'fxr')
    ktrans_error = mean([abs(fit_parameters(1)-fit_parameters(5)) abs(fit_parameters(1)-fit_parameters(6))]);
    ve_error = mean([abs(fit_parameters(2)-fit_parameters(7)) abs(fit_parameters(2)-fit_parameters(8))]);
    vp_error = mean([abs(fit_parameters(3)-fit_parameters(9)) abs(fit_parameters(3)-fit_parameters(10))]);
    plot_str(1) = {[' K_{trans} = ' num2str(fit_parameters(1),2) '�' num2str(ktrans_error,2)]};
    plot_str(2) = {[' V_e = ' num2str(fit_parameters(2),2) '�' num2str(ve_error,2)]};
    plot_str(3) = {[' \tau = ' num2str(fit_parameters(3),2) '�' num2str(vp_error,2)]};
    plot_str(4) = {[' residual = ' num2str(fit_parameters(4))]};
elseif strcmp(plot_data.model_name,'patlak')
    ktrans_error = mean([abs(fit_parameters(1)-fit_parameters(4)) abs(fit_parameters(1)-fit_parameters(5))]);
    vp_error = mean([abs(fit_parameters(2)-fit_parameters(6)) abs(fit_parameters(2)-fit_parameters(7))]);
    plot_str(1) = {[' K_{trans} = ' num2str(fit_parameters(1),2) '�' num2str(ktrans_error,2)]};
    plot_str(2) = {[' V_p = ' num2str(fit_parameters(2),2) '�' num2str(vp_error,2)]};
    plot_str(3) = {[' residual = ' num2str(fit_parameters(3))]};

else

end
text(plot_limits(1),plot_limits(3),plot_str,...
    'Color', 'black',...
    'VerticalAlignment','bottom',...
    'HorizontalAlignment','left');
title(plot_data.title,'Interpreter','none');
xlabel(plot_data.x_units);
ylabel(plot_data.y_units);