
expdir= '/Users/asaf/Dropbox (Personal)/KronauerLab/tracking/single_ant/single_ant_constant_2018_05_21_16_50_04_cam_0/'
% expdir = '/media/queen/AAnts102/hires_single_ant_2018_05_11_16_02_09/hires_single_ant_2018_05_11_16_02_09_cam_0';
Trck = trhandles.load(expdir);
avidir = Trck.croppedavidir;

source_avi_list = findAllImagesInFolders(avidir,'.avi');
L = length(source_avi_list);

workdir = [Trck.expdir,'MotionMapper/'];
if ~isdir(workdir), mkdir(workdir); end

%% 


%define any desired parameter changes here
parameters.samplingFreq = 15;
parameters.trainingSetSize = 5000;
parameters.rescaleSize=1;
parameters.numProcessors= 2;
%initialize parameters
parameters = setRunParameters(parameters);

firstFrame = 1;
lastFrame = [];


%% Run Alignment

%creating alignment directory
alignmentDirectory = [workdir '/aligned/'];
if ~exist(alignmentDirectory,'dir')
    mkdir(alignmentDirectory);
end

for ii=1:L    
    
    report('I',['Aligning avi ',num2str(ii),' out of ',num2str(L)]);
    inavi = [avidir,source_avi_list{ii}];
    [fpath,fname,fext]=fileparts(inavi);
    outavi = [alignmentDirectory,fname,fext];
    aligned_avi_list{ii} = outavi;
    if exist(outavi,'file')
        continue
    end
        
    antAlignment(Trck,inavi,outavi);
    
end


%% Find image subset statistics (a gui will pop-up here)

fprintf(1,'Finding Subset Statistics\n');
numToTest = parameters.pca_batchSize;
[pixels,thetas,means,stDevs,vidObjs] = findRadonPixels(alignmentDirectory,numToTest,parameters);


%% Find postural eigenmodes

fprintf(1,'Finding Postural Eigenmodes\n');
[vecs,vals,meanValues] = findPosturalEigenmodes(vidObjs,pixels,parameters);

vecs = vecs(:,1:parameters.numProjections);

figure
makeMultiComponentPlot_radon_fromVecs(vecs(:,1:25),25,thetas,pixels,[139 90]);
caxis([-3e-3 3e-3])
colorbar
title('First 25 Postural Eigenmodes','fontsize',14,'fontweight','bold');
drawnow;


%% Find projections for each data set

projectionsDirectory = [workdir,'/projections/'];
if ~exist(projectionsDirectory,'dir')
    mkdir(projectionsDirectory);
end


alignmentFolders = {alignmentDirectory};
fprintf(1,'Finding Projections\n');
for i=1:L
    
    fprintf(1,'\t Finding Projections for File #%4i out of %4i\n',i,L);
    projections = findProjections(alignmentFolders{i},vecs,meanValues,pixels,parameters);
    
    fileNum = [repmat('0',1,numZeros-length(num2str(i))) num2str(i)];
    fileName = imageFiles{i};
    
    save([projectionsDirectory 'projections_' fileNum '.mat'],'projections','fileName');
    
    clear projections
    clear fileNum
    clear fileName 
    
end


%% Use subsampled t-SNE to find training set 

fprintf(1,'Finding Training Set\n');
[trainingSetData,trainingSetAmps,projectionFiles] = ...
    runEmbeddingSubSampling(projectionsDirectory,parameters);

%% Run t-SNE on training set


fprintf(1,'Finding t-SNE Embedding for the Training Set\n');
[trainingEmbedding,betas,P,errors] = run_tSne(trainingSetData,parameters);


%% Find Embeddings for each file

fprintf(1,'Finding t-SNE Embedding for each file\n');
embeddingValues = cell(L,1);
for i=1:L
    
    fprintf(1,'\t Finding Embbeddings for File #%4i out of %4i\n',i,L);
    
    load(projectionFiles{i},'projections');
    projections = projections(:,1:parameters.pcaModes);
    
    [embeddingValues{i},~] = ...
        findEmbeddings(projections,trainingSetData,trainingEmbedding,parameters);

    clear projections
    
end

%% Make density plots



maxVal = max(max(abs(combineCells(embeddingValues))));
maxVal = round(maxVal * 1.1);

sigma = maxVal / 40;
numPoints = 501;
rangeVals = [-maxVal maxVal];

[xx,density] = findPointDensity(combineCells(embeddingValues),sigma,numPoints,rangeVals);

densities = zeros(numPoints,numPoints,L);
for i=1:L
    [~,densities(:,:,i)] = findPointDensity(embeddingValues{i},sigma,numPoints,rangeVals);
end


figure
maxDensity = max(density(:));
imagesc(xx,xx,density)
axis equal tight off xy
caxis([0 maxDensity * .8])
colormap(jet)
colorbar



figure

N = ceil(sqrt(L));
M = ceil(L/N);
maxDensity = max(densities(:));
for i=1:L
    subplot(M,N,i)
    imagesc(xx,xx,densities(:,:,i))
    axis equal tight off xy
    caxis([0 maxDensity * .8])
    colormap(jet)
    title(['Data Set #' num2str(i)],'fontsize',12,'fontweight','bold');
end



close_parpool

