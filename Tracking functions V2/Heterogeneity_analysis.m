function Heterogeneity_analysis(lowCutoff, highCutoff, pointSelection);
fprintf('\nUser defined point selection still in development. Not implemented in V2 yet\n\n\n');

    if nargin <3
        lowCutoff = 0;
        highCutoff = 1;
        pointSelection = 0;
        fprintf('You forgot to set the low cutoff high cutoff and whether you want to select points of interest (use 1 for yes).\nI set these values to 0, 1 and 0, respectively. This is equivalent to typing: "Heterogeneity_analysis(0,1,0)"\n\n');
    end
        
    [filenames_tracks,path_tracks] = uigetfile('multiselect','on','.mat','Select tracked file to find heterogenity ');
    cd(path_tracks);
    [filenames_bf,path_bf] =uigetfile('multiselect','on','.jpg','Select the corresponding BF image');

    singleTrackvsManyTracks  = iscell(filenames_tracks);
    
    prompt = {'Enter desired filter width','Enter desired filter sigma'};
    title = 'Deff heterogeneity gaussian filter settings';
    dims = [1 35];
    definput = {'6','2'};
    filterSettings = inputdlg(prompt,title,dims,definput);

if singleTrackvsManyTracks == 0
    cd(path_tracks)

    result = struct();
    disp(filenames_tracks);
    result = importdata(filenames_tracks);

    cd(path_bf)
    im = imread(filenames_bf);
    imageName = filenames_bf;
    
    Plot_data(result, im, imageName, lowCutoff, highCutoff, pointSelection, filterSettings);
else
    for w = 1:length(filenames_tracks)
        cd(path_tracks)

        result = struct();
        disp(filenames_tracks{w})
        result = importdata(filenames_tracks{w});

        cd(path_bf)
        im = imread(filenames_bf{w});

        imageName = filenames_bf{w};
        
        Plot_data(result, im, imageName, lowCutoff, highCutoff, pointSelection, filterSettings);
        clearvars -except filenames_bf filenames_tracks path_bf path_tracks lowCutoff highCutoff pointSelection filterSettings


    end
end
end

function Plot_data(result, im, imageName, lowCutoff, highCutoff, pointSelection, filterSettings)

    x = result.lin.Dlin_centroid_x{:};
    y = result.lin.Dlin_centroid_y{:};

    x2 = y;
    y2 = x;

    x = x2;
    y = y2; % somehow I flipped them - will fix this later

    x_length = length(im(:,1));
    y_length = length(im(1,:));

    Averaging_array = zeros(x_length,y_length);
    Counting_array = zeros(x_length,y_length);


    for i = 1:length(result.lin.Dlin_centroid_y{1,1}) % loop through each cell then loop through all values within cell
        for k = 1:length(x{i})
            Averaging_array(round(x{1,i}(k)),round(y{1,i}(k))) = Averaging_array(round(x{1,i}(k)),round(y{1,i}(k))) + result.lin.D_lin{1,1}(i);
            Counting_array(round(x{1,i}(k)),round(y{1,i}(k))) = Counting_array(round(x{1,i}(k)),round(y{1,i}(k))) + 1;
        end

    end
    %%
    Bigger = Averaging_array * 1000;

    avg_array = Bigger./Counting_array;
    avg_array_renorm = avg_array ./ 1000;

    a = avg_array_renorm;

    nanMask = isnan(a);
    [r, c] = find(~nanMask);
    [rNan, cNan] = find(nanMask);
    Interpolated = scatteredInterpolant(c, r, a(~nanMask), 'nearest');
    interpVals = Interpolated(cNan, rNan);
    data = a;
    data(nanMask) = interpVals;

    % Filter the data, replacing Nans afterward:
    filtWidth = str2double(filterSettings{1});
    filtSigma = str2double(filterSettings{2}); 

    imageFilter=fspecial('gaussian',filtWidth,filtSigma);

    dataFiltered = imfilter(data, imageFilter, 'replicate', 'conv');
    % should probably change this to imgaussfilt later
    dataFiltered(nanMask) = nan;
%%  
    %imputed = knnimpute(dataFiltered,1, 'Distance', 'Euclidean');
    oppNaN = 1- nanMask;
    
          values = [];
          %dataFiltered(dim1,dime2)
          %values = 
          for x = 2:length(dataFiltered(:,1))-2 % should set a value to change what width to expand data
               for y = 2:length(dataFiltered(1,:))-2  % should set a value to change what width to expand data
                   values(x,y) = nanmean(nanmean(dataFiltered(x-1:x+1, y-1:y+1))); % should set a value to change what width to expand data
               end
          end
          
%      values(1:200,250:683) = 0;      
%      values(500:565,600:683) = 0;
     values(values >= 1.5) = 1.5;
     values(values == 0) = NaN;
    nanMask_expanded  = isnan(values);
    oppNaN = 1 - nanMask_expanded;
    
    figure('DefaultAxesFontSize',25);
    ax1 = axes;
    imagesc(im);
    colormap(ax1, 'gray');
    ax = gca;
    ax2 = axes;
    %im = imagesc(ax2, dataFiltered); %only shows real data
    im = imagesc(ax2,values); % shows pixel expanded data
    im.AlphaData = (oppNaN );
    mymap = load('HeterogeneityColormapRedYellowGreen.mat');
    colormap(ax2, mymap.mymap);
    caxis([lowCutoff highCutoff]); % use this for custom colormap loaded from previous command
    %colormap(ax2, 'jet');caxis([lowCutoff highCutoff]);
    ax2.Visible = 'off';
    ax.Visible = 'off';
    linkprop([ax1 ax2],'Position');
    hold off
    h = colorbar;
    ylabel(h, 'Deff uM^2/s');
    saveas(gcf,[imageName '_Heterogeneity.png']);
    savefig([imageName '_Heterogeneity.fig']);

    if pointSelection == 1;
               
        disp('User specified landmark analysis')
        
        title('choose verties of cells')
        poly = impoly
        pos = getPosition(poly)

        in = inpolygon(Xc,Yc,pos(:,1),pos(:,2));
        nnz(in)
        plot(Xc(in),Yc(in),'ro')

        % Get the center of the cel;
        title('choose center of nucleus of your cell')
        [xcenter, ycenter] = ginput(1)
        %subset your list with this index
        Xcr = Xc(in);
        Ycr = Yc(in);
    end


    
end

