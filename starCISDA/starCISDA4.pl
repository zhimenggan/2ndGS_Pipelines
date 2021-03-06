#!/usr/bin/env  perl5
use  strict;
use  warnings;
use  v5.22;

## Perl5 version >= 5.22
## You can create a symbolic link for perl5 by using "sudo  ln  /usr/bin/perl   /usr/bin/perl5" in Ubuntu.
## Suffixes of all self-defined global variables must be "_g".
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $genome_g = '';  ## such as "mm10", "ce11", "hg38".
my $input_g  = '';  ## such as "4-finalFASTQ"
my $output_g = '';  ## such as "5-rawBAM"

{
## Help Infromation
my $HELP = '
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        Welcome to use starCISDA (small-scale TELP-assisted rapid ChIP–seq Data Analyzer), version 0.9.0, 2017-10-01.
        starCISDA is a Pipeline for Single-end and Paired-end small-scale TELP-assisted rapid ChIP–seq Data Analysis by Integrating Lots of Softwares.

        Step 4: Mapping reads to the reference genome by using 8 softwares (mappers or aligners): BWA-mem, Bowtie2, Novoalign, Subread, Stampy, GSNAP, BBMap, NextGenMap.
                Assess the quality of BAM files to identify possible sequencing errors or biases by using 10 softwares:
                    SAMtools, Subread utilities, FASTQC, SAMstat, qualimap, deepTools, PRESEQ, Picard, goleft and phantompeakqualtools.
                And aggregate the results from FastQC, Bowtie2, Picard, Samtools, Preseq, Qualimap, goleft analyses across many samples into a single report by using MultiQC.

        Usage:
               perl  starCISDA4.pl    [-version]    [-help]   [-genome RefGenome]    [-in inputDir]    [-out outDir]
        For instance:
               perl  starCISDA4.pl   -genome hg38   -in 4-finalFASTQ   -out 5-rawBAM    > starCISDA4.runLog

        ----------------------------------------------------------------------------------------------------------
        Optional arguments:
        -version        Show version number of this program and exit.

        -help           Show this help message and exit.

        Required arguments:
        -genome RefGenome   "RefGenome" is the short name of your reference genome, such as "mm10", "ce11", "hg38".    (no default)

        -in inputDir        "inputDir" is the name of input path that contains your FASTQ files.  (no default)

        -out outDir         "outDir" is the name of output path that contains your running results (BAM files) of this step.  (no default)
        -----------------------------------------------------------------------------------------------------------

        For more details about this pipeline and other NGS data analysis piplines, please visit https://github.com/CTLife/2ndGS_Pipelines

        Yong Peng @ Jie Qiao Lab, yongp@outlook.com, Key Laboratory of Assisted Reproduction at Third Hospital,
        Academy for Advanced Interdisciplinary Studies, and Peking-Tsinghua Center for Life Sciences (CLS), Peking University, China.
        ------------------------------------------------------------------------------------------------------------------------------------------------------
        ------------------------------------------------------------------------------------------------------------------------------------------------------
';

## Version Infromation
my $version = "    The Fourth Step of starCISDA (small-scale TELP-assisted rapid ChIP–seq Data Analyzer), version 0.9.0, 2017-10-01.";

## Keys and Values
if ($#ARGV   == -1)   { say  "\n$HELP\n";  exit 0;  }       ## when there are no any command argumants.
if ($#ARGV%2 ==  0)   { @ARGV = (@ARGV, "-help") ;  }       ## when the number of command argumants is odd.
my %args = @ARGV;

## Initialize  Variables
$genome_g = 'hg38';           ## This is only an initialization value or suggesting value, not default value.
$input_g  = '4-finalFASTQ';   ## This is only an initialization value or suggesting value, not default value.
$output_g = '5-rawBAM';       ## This is only an initialization value or suggesting value, not default value.

## Available Arguments
my $available = "   -version    -help   -genome   -in   -out  ";
my $boole = 0;
while( my ($key, $value) = each %args ) {
    if ( ($key =~ m/^\-/) and ($available !~ m/\s$key\s/) ) {say    "\n\tCann't recognize $key";  $boole = 1; }
}
if($boole == 1) {
    say  "\tThe Command Line Arguments are wrong!";
    say  "\tPlease see help message by using 'perl  starCISDA4.pl  -help' \n";
    exit 0;
}

## Get Arguments
if ( exists $args{'-version' }   )     { say  "\n$version\n";    exit 0; }
if ( exists $args{'-help'    }   )     { say  "\n$HELP\n";       exit 0; }
if ( exists $args{'-genome'  }   )     { $genome_g = $args{'-genome'  }; }else{say   "\n -genome is required.\n";   say  "\n$HELP\n";    exit 0; }
if ( exists $args{'-in'      }   )     { $input_g  = $args{'-in'      }; }else{say   "\n -in     is required.\n";   say  "\n$HELP\n";    exit 0; }
if ( exists $args{'-out'     }   )     { $output_g = $args{'-out'     }; }else{say   "\n -out    is required.\n";   say  "\n$HELP\n";    exit 0; }

## Conditions
$genome_g =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";
$input_g  =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";
$output_g =~ m/^\S+$/    ||  die   "\n\n$HELP\n\n";

## Print Command Arguments to Standard Output
say  "\n
        ################ Arguments ###############################
                Reference Genome:  $genome_g
                Input       Path:  $input_g
                Output      Path:  $output_g
        ###############################################################
\n";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say    "\n\n\n\n\n\n##################################################################################################";
say    "Running......";

sub myMakeDir  {
    my $path = $_[0];
    if ( !( -e $path) )  { system("mkdir  -p  $path"); }
    if ( !( -e $path) )  { mkdir $path  ||  die; }
}

my $output2_g = "$output_g/QC_Results";
&myMakeDir($output_g);
&myMakeDir($output2_g);

opendir(my $DH_input_g, $input_g)  ||  die;
my @inputFiles_g = readdir($DH_input_g);
my $pattern_g    = "[-.0-9A-Za-z]+";
my $numCores_g   = 4;
###################################################################################################################################################################################################





###################################################################################################################################################################################################
## Context specific:
my  $commonPath_g      = "/media/yp/ProgramFiles/.MyProgramFiles/4_ChIPseq/5-Mapping";

my  $BWA_index_g       = "$commonPath_g/bwa/RefGenomes/$genome_g/$genome_g";
my  $Bowtie2_index_g   = "$commonPath_g/bowtie2/RefGenomes/$genome_g/$genome_g";
my  $BWA_ensembl_index_g = "$commonPath_g/bwa/RefGenomes/$genome_g.ensembl/$genome_g.ensembl";
my  $Bowtie2_ensembl_index_g   = "$commonPath_g/bowtie2/RefGenomes/$genome_g.ensembl/$genome_g.ensembl";

my  $Novoalign_index_g = "$commonPath_g/novocraft/RefGenomes/$genome_g/$genome_g";
my  $Subread_index_g   = "$commonPath_g/subread/RefGenomes/$genome_g/$genome_g";
my  $GSNAP_index_g     = "RefGenomes/$genome_g/$genome_g/$genome_g";
my  $BBMap_index_g     = "/media/yp/ProgramFiles/.MyProgramFiles/4_ChIPseq/3-Remove-Correct/bbmap/RefGenomes/$genome_g";
my  $Stampy_index_g    = "$commonPath_g/stampy/RefGenomes/$genome_g/$genome_g";
my  $NGM_index_g       = "$commonPath_g/NextGenMap/RefGenomes/Shortcuts/$genome_g/$genome_g.fasta";

###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "Checking all the necessary softwares in this step......" ;

sub printVersion  {
    my $software = $_[0];
    system("echo    '##############################################################################'  >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("echo    '#########$software'                                                              >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("$software                                                                                 >> $output2_g/VersionsOfSoftwares.txt   2>&1");
    system("echo    '\n\n\n\n\n\n'                                                                    >> $output2_g/VersionsOfSoftwares.txt   2>&1");
}

sub fullPathApp  {
    my $software = $_[0];
    say($software);
    system("which   $software  > yp_my_temp_1.$software.txt");
    open(tempFH, "<", "yp_my_temp_1.$software.txt")  or  die;
    my @fullPath1 = <tempFH>;
    ($#fullPath1 == 0)  or  die;
    system("rm  yp_my_temp_1.$software.txt");
    $fullPath1[0] =~ s/\n$//  or  die;
    return($fullPath1[0]);
}

my  $Picard_g = &fullPathApp("picard.jar");
my  $phantompeakqualtools_g = &fullPathApp("run_spp.R");

&printVersion("bwa  mem");
&printVersion("bowtie2   --version");
&printVersion("subread-align  -v");
&printVersion("novoalign --version");
&printVersion("gsnap --version");
&printVersion("bbmap.sh -h");
&printVersion("stampy.py --help");
&printVersion("ngm -h");

&printVersion("samtools");
&printVersion("fastqc    -v");
&printVersion("samstat   -v");
&printVersion("Rscript  $phantompeakqualtools_g");
&printVersion("preseq");
&printVersion("qualimap  -v");
&printVersion("multiqc   --version");
&printVersion("propmapped");     ## in subread
&printVersion("qualityScores");  ## in subread
&printVersion("goleft  -v");
&printVersion("plotFingerprint --version"); 

&printVersion("java  -jar  $Picard_g   CollectIndependentReplicateMetrics  --version");
&printVersion("java  -jar  $Picard_g   CollectAlignmentSummaryMetrics      --version");
&printVersion("java  -jar  $Picard_g   CollectBaseDistributionByCycle      --version");
&printVersion("java  -jar  $Picard_g   CollectGcBiasMetrics                --version");
&printVersion("java  -jar  $Picard_g   CollectInsertSizeMetrics            --version");
&printVersion("java  -jar  $Picard_g   CollectJumpingLibraryMetrics        --version");
&printVersion("java  -jar  $Picard_g   CollectMultipleMetrics              --version");
&printVersion("java  -jar  $Picard_g   CollectOxoGMetrics                  --version");
&printVersion("java  -jar  $Picard_g   CollectQualityYieldMetrics          --version");
&printVersion("java  -jar  $Picard_g   CollectSequencingArtifactMetrics    --version");
&printVersion("java  -jar  $Picard_g   CollectTargetedPcrMetrics           --version");
&printVersion("java  -jar  $Picard_g   CollectWgsMetrics                   --version");
&printVersion("java  -jar  $Picard_g   EstimateLibraryComplexity           --version");
&printVersion("java  -jar  $Picard_g   MeanQualityByCycle                  --version");
&printVersion("java  -jar  $Picard_g   QualityScoreDistribution            --version");
###################################################################################################################################################################################################





###################################################################################################################################################################################################
{
say   "\n\n\n\n\n\n##################################################################################################";
say   "Checking all the input file names ......";
my @groupFiles = ();
my $fileNameBool = 1;
for ( my $i=0; $i<=$#inputFiles_g; $i++ ) {
        next unless $inputFiles_g[$i] =~ m/\.fastq$/;
        next unless $inputFiles_g[$i] !~ m/^[.]/;
        next unless $inputFiles_g[$i] !~ m/[~]$/;
        next unless $inputFiles_g[$i] !~ m/^QC_Results$/;
        next unless $inputFiles_g[$i] !~ m/^unpaired/;
        say   "\t......$inputFiles_g[$i]" ;
        my $temp = $inputFiles_g[$i];
        $groupFiles[++$#groupFiles] = $inputFiles_g[$i];
        $temp =~ m/^(\d+)_($pattern_g)_(Rep[1-9])/   or  die   "wrong-1: ## $temp ##";
        $temp =~ m/_(Rep[1-9])\.fastq$/  or  $temp =~ m/_(Rep[1-9])_?([1-2]?)\.fastq$/   or  die   "wrong-2: ## $temp ##";
        if($temp !~ m/^((\d+)_($pattern_g)_(Rep[1-9]))(_[1-2])?\.fastq$/) {
             $fileNameBool = 0;
        }
}
if($fileNameBool == 1)  { say    "\n\t\tAll the file names are passed.\n";  }
@groupFiles   = sort(@groupFiles);
my $numGroup  = 0;
my $noteGroup = 0;
for ( my $i=0; $i<=$#groupFiles; $i++ ) {
    $groupFiles[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])/  or  die;
    my $n1 = $1;
    $n1>=1  or  die;
    if($noteGroup != $n1) {say "\n\t\tGroup $n1:";  $numGroup++; }
    say  "\t\t\t$groupFiles[$i]";
    $noteGroup = $n1;
}
say  "\n\t\tThere are $numGroup groups.";
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "Detecting single-end and paired-end FASTQ files in input folder ......";     ## The fastq files are same between input folder and ouput folder.
my @singleEnd_g   = ();
my @pairedEnd_g   = ();
open(seqFiles_FH_g, ">", "$output2_g/singleEnd-pairedEnd-Files.txt")  or  die;
for ( my $i=0; $i<=$#inputFiles_g; $i++ ) {
    next unless $inputFiles_g[$i] =~ m/\.fastq$/;
    next unless $inputFiles_g[$i] !~ m/^[.]/;
    next unless $inputFiles_g[$i] !~ m/[~]$/;
    next unless $inputFiles_g[$i] !~ m/^unpaired/;
    next unless $inputFiles_g[$i] !~ m/^QC_Results$/;
    say    "\t......$inputFiles_g[$i]";
    $inputFiles_g[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])_?([1-2]?)\.fastq$/   or  die;
    if ($inputFiles_g[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])\.fastq$/) {   ## sinlge end sequencing files.
        $inputFiles_g[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])\.fastq$/  or  die;
        $singleEnd_g[$#singleEnd_g+1] =  $inputFiles_g[$i];
        say         "\t\t\t\tSingle-end sequencing files: $inputFiles_g[$i]\n";
        say  seqFiles_FH_g  "Single-end sequencing files: $inputFiles_g[$i]\n";
    }else{     ## paired end sequencing files.
        $inputFiles_g[$i] =~ m/^(\d+)_($pattern_g)_(Rep[1-9])_([1-2])\.fastq$/  or  die;
        if ($inputFiles_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/) { ## The two files of one paired sequencing sample are always side by side.
            my $temp = $1;
            my $end1 = $temp."_1.fastq";
            my $end2 = $temp."_2.fastq";
            (-e  "$input_g/$end1")  or die;
            (-e  "$input_g/$end2")  or die;
            $pairedEnd_g[$#pairedEnd_g+1] =  $end1;
            $pairedEnd_g[$#pairedEnd_g+1] =  $end2;
            say        "\t\t\t\tPaired-end sequencing files: $end1,  $end2\n";
            say seqFiles_FH_g  "Paired-end sequencing files: $end1,  $end2\n";
        }
    }
}
( ($#pairedEnd_g+1)%2 == 0 )  or die;
say   seqFiles_FH_g  "\n\n\n\n\n";
say   seqFiles_FH_g  "All single-end sequencing files:@singleEnd_g\n\n\n";
say   seqFiles_FH_g  "All paired-end sequencing files:@pairedEnd_g\n\n\n";
say          "\t\t\t\tAll single-end sequencing files:@singleEnd_g\n\n";
say          "\t\t\t\tAll paired-end sequencing files:@pairedEnd_g\n\n";
my $numSingle_g = $#singleEnd_g + 1;
my $numPaired_g = $#pairedEnd_g + 1;
say seqFiles_FH_g   "\nThere are $numSingle_g single-end sequencing files.\n";
say seqFiles_FH_g   "\nThere are $numPaired_g paired-end sequencing files.\n";
say           "\t\t\t\tThere are $numSingle_g single-end sequencing files.\n";
say           "\t\t\t\tThere are $numPaired_g paired-end sequencing files.\n";
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_1  {
    my $dir1      =  $_[0];   ## All the SAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $SAMtools  = "$QCresults/1_SAMtools";
    my $FastQC    = "$QCresults/2_FastQC";
    my $qualimap  = "$QCresults/3_qualimap";
    my $samstat   = "$QCresults/4_samstat";
    my $MultiQC1  = "$QCresults/5_MultiQC_FastQC";
    my $MultiQC2  = "$QCresults/5_MultiQC_qualimap";
    my $MultiQC3  = "$QCresults/5_MultiQC_SAMtools";
    my $MultiQC4  = "$QCresults/5_MultiQC_Bowtie2";

    &myMakeDir($QCresults);
    &myMakeDir($SAMtools);
    &myMakeDir($FastQC);
    &myMakeDir($qualimap);
    &myMakeDir($samstat);
    &myMakeDir($MultiQC1);
    &myMakeDir($MultiQC2);
    &myMakeDir($MultiQC3);
    &myMakeDir($MultiQC4);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using SAMtools, FastQC, qualimap, samstat and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.sam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.sam$//  ||  die;
        system("samtools  sort  -m 2G  -o $dir1/$temp.bam   --output-fmt bam  -T $dir1/yp_$temp   --threads $numCores_g    $dir1/$temp.sam    >>$SAMtools/$temp.runLog    2>&1");
        system("samtools  index           $dir1/$temp.bam      >>$SAMtools/$temp.index.runLog  2>&1");
        system("samtools  flagstat        $dir1/$temp.bam      >>$SAMtools/$temp.flagstat      2>&1");
        system(`samtools  idxstats        $dir1/$temp.bam      >>$SAMtools/$temp.idxstats      2>&1`);
        system( "fastqc    --outdir $FastQC    --threads $numCores_g  --format bam   --kmers 7    $dir1/$temp.bam                   >> $FastQC/$temp.runLog      2>&1" );
        system( "qualimap  bamqc  -bam $dir1/$temp.bam   -c  -ip  -nt $numCores_g   -outdir $qualimap/$temp   --java-mem-size=16G   >> $qualimap/$temp.runLog    2>&1" );
        system( "samstat   $dir1/$temp.bam      >> $samstat/$temp.runLog         2>&1");
        system( "rm   $dir1/$temp.sam" );
    }

    system( "multiqc    --title FastQC     --verbose  --export   --outdir $MultiQC1          $FastQC            >> $MultiQC1/MultiQC.FastQC.runLog     2>&1" );
    system( "multiqc    --title qualimap   --verbose  --export   --outdir $MultiQC2          $qualimap          >> $MultiQC2/MultiQC.qualimap.runLog   2>&1" );
    system( "multiqc    --title SAMtools   --verbose  --export   --outdir $MultiQC3          $SAMtools          >> $MultiQC3/MultiQC.SAMtools.runLog   2>&1" );
    system( "multiqc    --title Bowtie2    --verbose  --export   --outdir $MultiQC4          $dir1/*.runLog     >> $MultiQC4/MultiQC.Bowtie2.runLog    2>&1" );

}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_2  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $Fingerprint    = "$QCresults/6_Fingerprint";
    my $Fingerprint2   = "$QCresults/7_Fingerprint2";
    my $goleft         = "$QCresults/8_goleft";
    my $phantompeak    = "$QCresults/9_phantompeakqualtools";
    my $MultiQC1       = "$QCresults/10_MultiQC_goleft";

    &myMakeDir($QCresults);
    &myMakeDir($Fingerprint);
    &myMakeDir($Fingerprint2);
    &myMakeDir($goleft);
    &myMakeDir($phantompeak);
    &myMakeDir($MultiQC1);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using plotFingerprint in deepTools, goleft , phantompeakqualtools and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.bam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.bam$//  ||  die;
        system("plotFingerprint --bamfiles $dir1/$temp.bam   --extendReads 220  --numberOfSamples 1000000    --plotFile $Fingerprint/$temp.pdf    --plotTitle $temp   --outRawCounts  $Fingerprint/$temp.cov   --outQualityMetrics $Fingerprint/$temp.Metrics.txt   --numberOfProcessors $numCores_g   --binSize 500    >> $Fingerprint/$temp.runLog    2>&1");                           
        system("plotFingerprint --bamfiles $dir1/$temp.bam   --extendReads 220  --numberOfSamples 1000000    --plotFile $Fingerprint2/$temp.pdf   --plotTitle $temp   --outRawCounts  $Fingerprint2/$temp.cov  --outQualityMetrics $Fingerprint2/$temp.Metrics.txt  --numberOfProcessors $numCores_g   --binSize 5000   >> $Fingerprint2/$temp.runLog   2>&1");                                   
        system("goleft   covstats    $dir1/$temp.bam  > $goleft/$temp.covstats " );
        system("goleft   indexcov  --sex chrX,chrY  -d $goleft/$temp  $dir1/$temp.bam  > $goleft/$temp.indexcov.runLog      2>&1" );
        &myMakeDir("$phantompeak/$temp");
        system("Rscript    $phantompeakqualtools_g    -c=$dir1/$temp.bam   -p=$numCores_g   -odir=$phantompeak/$temp    -savd=$phantompeak/$temp/rdatafile.RData     -savp=$phantompeak/$temp/plotdatafile.pdf   -out=$phantompeak/$temp/resultfile.txt   >> $phantompeak/$temp.runLog   2>&1");
    }
    system("sleep 5s");
    system( "multiqc    --title goleft    --verbose  --export   --outdir $MultiQC1          $goleft     >> $MultiQC1/MultiQC.goleft.runLog    2>&1" );

}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_3  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $PRESEQ    = "$QCresults/11_PRESEQ";
    my $PicardDir = "$QCresults/12_Picard";
    my $MultiQC1  = "$QCresults/13_MultiQC_PRESEQ";
    my $MultiQC2  = "$QCresults/13_MultiQC_Picard";

    &myMakeDir($QCresults);
    &myMakeDir($PRESEQ);
    &myMakeDir($PicardDir);
    &myMakeDir($MultiQC1);
    &myMakeDir($MultiQC2);

    opendir(my $FH_Files, $dir1) || die;
    my @Files = readdir($FH_Files);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of all BAM files by using PRESEQ, Picard and MultiQC ......";
    for ( my $i=0; $i<=$#Files; $i++ ) {
        next unless $Files[$i] =~ m/\.bam$/;
        next unless $Files[$i] !~ m/^[.]/;
        next unless $Files[$i] !~ m/[~]$/;
        my $temp = $Files[$i];
        say    "\t......$temp";
        $temp =~ s/\.bam$//  ||  die;
        system("preseq  c_curve     -output  $PRESEQ/$temp.c_curve.pe.PRESEQ       -step 1000000    -verbose   -pe  -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.c_curve.pe.runLog   2>&1");
        system("preseq  c_curve     -output  $PRESEQ/$temp.c_curve.se.PRESEQ       -step 1000000    -verbose        -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.c_curve.se.runLog   2>&1");
        system("preseq  lc_extrap   -output  $PRESEQ/$temp.lc_extrap.pe.PRESEQ     -step 1000000    -verbose   -pe  -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.lc_extrap.pe.runLog   2>&1");
        system("preseq  lc_extrap   -output  $PRESEQ/$temp.lc_extrap.se.PRESEQ     -step 1000000    -verbose        -bam  $dir1/$temp.bam    >> $PRESEQ/$temp.lc_extrap.se.runLog   2>&1");

        &myMakeDir("$PicardDir/$temp");
        #system("java  -jar   $Picard_g   CollectIndependentReplicateMetrics      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/0_CollectIndependentReplicateMetrics     VCF=null    MINIMUM_MQ=20                                    >> $PicardDir/$temp/0.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectAlignmentSummaryMetrics          INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/1_CollectAlignmentSummaryMetrics                                                                      >> $PicardDir/$temp/1.runLog   2>&1" );
        system("java  -jar   $Picard_g   EstimateLibraryComplexity               INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/2_EstimateLibraryComplexity                                                                           >> $PicardDir/$temp/2.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectInsertSizeMetrics                INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/3_CollectInsertSizeMetrics               HISTOGRAM_FILE=$PicardDir/$temp/3.pdf  MINIMUM_PCT=0.05      >> $PicardDir/$temp/3.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectJumpingLibraryMetrics            INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/4_CollectJumpingLibraryMetrics                                                                        >> $PicardDir/$temp/4.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectMultipleMetrics                  INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/5_CollectMultipleMetrics                                                                              >> $PicardDir/$temp/5.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectBaseDistributionByCycle          INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/6_CollectBaseDistributionByCycle         CHART_OUTPUT=$PicardDir/$temp/6.pdf                          >> $PicardDir/$temp/6.runLog   2>&1" );
        system("java  -jar   $Picard_g   CollectQualityYieldMetrics              INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/7_CollectQualityYieldMetrics                                                                          >> $PicardDir/$temp/7.runLog   2>&1" );
        #system("java  -jar   $Picard_g   CollectWgsMetrics                       INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/8_CollectWgsMetricsFromQuerySorted       REFERENCE_SEQUENCE=null                                      >> $PicardDir/$temp/8.runLog   2>&1" );
        system("java  -jar   $Picard_g   MeanQualityByCycle                      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/9_MeanQualityByCycle                     CHART_OUTPUT=$PicardDir/$temp/9.pdf                          >> $PicardDir/$temp/9.runLog   2>&1" );
        system("java  -jar   $Picard_g   QualityScoreDistribution                INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/10_QualityScoreDistribution              CHART_OUTPUT=$PicardDir/$temp/10.pdf                         >> $PicardDir/$temp/10.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectGcBiasMetrics                    INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/11_CollectGcBiasMetrics                  CHART_OUTPUT=$PicardDir/$temp/11.pdf   SUMMARY_OUTPUT=$PicardDir/$temp/11.summary.output                  >> $PicardDir/$temp/11.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectOxoGMetrics                      INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/12_CollectOxoGMetrics                    REFERENCE_SEQUENCE=null                                      >> $PicardDir/$temp/12.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectSequencingArtifactMetrics        INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/13_CollectSequencingArtifactMetrics                                       >> $PicardDir/$temp/13.runLog  2>&1" );
        #system("java  -jar   $Picard_g   CollectTargetedPcrMetrics               INPUT=$dir1/$temp.bam     OUTPUT=$PicardDir/$temp/14_CollectTargetedPcrMetrics                                        >> $PicardDir/$temp/14.runLog  2>&1" );
    }
    system( "multiqc  --title PRESEQ    --verbose  --export  --outdir $MultiQC1          $PRESEQ                 >> $MultiQC1/MultiQC.PRESEQ.runLog   2>&1" );
    system( "multiqc  --title Picard    --verbose  --export  --outdir $MultiQC2          $PicardDir              >> $MultiQC2/MultiQC.Picard.runLog   2>&1" );
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
sub  myQC_BAM_4  {
    my $dir1      =  $_[0];   ## All the BAM files must be in this folder.
    my $QCresults = "$dir1/QC_Results";
    my $SubreadUti= "$QCresults/14_SubreadUti";

    &myMakeDir("$QCresults");
    &myMakeDir("$SubreadUti");

    opendir(my $DH_map, $dir1) || die;
    my @mapFiles = readdir($DH_map);

    say   "\n\n\n\n\n\n##################################################################################################";
    say   "Detecting the quality of bam files by using Subreads utilities and goleft ......";
    for (my $i=0; $i<=$#mapFiles; $i++) {
           next unless $mapFiles[$i] =~ m/\.bam$/;
           next unless $mapFiles[$i] !~ m/^[.]/;
           next unless $mapFiles[$i] !~ m/[~]$/;
           my $temp = $mapFiles[$i];
           $temp =~ s/\.bam$//  ||  die;
           say   "\t......$mapFiles[$i]";
           system("propmapped   -i $dir1/$temp.bam                    -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("echo      '\n\n\n\n\n'                                                                  >> $SubreadUti/$temp.prommapped      2>&1");
           system("propmapped   -i $dir1/$temp.bam       -f           -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("echo      '\n\n\n\n\n'                                                                  >> $SubreadUti/$temp.prommapped      2>&1");
           system("propmapped   -i $dir1/$temp.bam       -f   -p      -o $SubreadUti/$temp.prommapped      >> $SubreadUti/$temp.prommapped      2>&1");
           system("qualityScores   --BAMinput   -i $dir1/$temp.bam    -o $SubreadUti/$temp.qualityScores   >> $SubreadUti/$temp.qualityScores   2>&1");
     }
}
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $BWA2_g  = "$output_g/1_Trim_BWAmem";
&myMakeDir($BWA2_g);
{ ## Start BWA
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using BWA mem ......";
my $inputDir2 = "2-mergedFASTQ";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq"  eq  $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$BWA2_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("bwa mem  -t $numCores_g   -L 1,1   -T 0     $BWA_index_g   $inputDir2/$end1.fastq  $inputDir2/$end2.fastq    >$BWA2_g/$temp.sam");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("bwa mem  -t $numCores_g   -L 1,1  -T 0        $BWA_index_g   $inputDir2/$temp.fastq   >$BWA2_g/$temp.sam");
}
} ## End BWA
&myQC_BAM_1($BWA2_g);
###################################################################################################################################################################################################




 
###################################################################################################################################################################################################
my $BWA_g  = "$output_g/2_BWAmem";
&myMakeDir($BWA_g);
{ ## Start BWA
say   "\n\n\n\n\n\n##################################################################################################";

say   "Mapping reads to the reference genome by using BWA mem ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq"  eq  $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$BWA_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("bwa mem  -t $numCores_g  -T 0        $BWA_index_g   $input_g/$end1.fastq  $input_g/$end2.fastq    >$BWA_g/$temp.sam");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("bwa mem  -t $numCores_g  -T 0       $BWA_index_g   $input_g/$temp.fastq   >$BWA_g/$temp.sam");
}
} ## End BWA
&myQC_BAM_1($BWA_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $Bowtie2_g   = "$output_g/3_Trim_Bowtie2";
&myMakeDir($Bowtie2_g);
{ ## Start Bowtie2
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using Bowtie2 ......";
my $inputDir2 = "2-mergedFASTQ";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$Bowtie2_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("bowtie2     --threads $numCores_g   -q   -t  -N 1  -L 25  --phred33   --local    -x $Bowtie2_index_g    -1 $inputDir2/$end1.fastq        -2 $inputDir2/$end2.fastq     -S $Bowtie2_g/$temp.sam    >>$Bowtie2_g/$temp.runLog  2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("bowtie2    --threads $numCores_g   -q   -t  -N 1  -L 25   --phred33   --local    -x $Bowtie2_index_g    -U $inputDir2/$temp.fastq       -S $Bowtie2_g/$temp.sam    >>$Bowtie2_g/$temp.runLog  2>&1");
}
}  ## End Bowtie2
&myQC_BAM_1($Bowtie2_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $Bowtie_g   = "$output_g/4_Bowtie2";
&myMakeDir($Bowtie_g);
{ ## Start Bowtie2
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using Bowtie2 ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$Bowtie_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("bowtie2     --threads $numCores_g   -q   -t  -N 1  -L 25   --phred33   --end-to-end    -x $Bowtie2_index_g    -1 $input_g/$end1.fastq        -2 $input_g/$end2.fastq     -S $Bowtie_g/$temp.sam    >>$Bowtie_g/$temp.runLog  2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("bowtie2    --threads $numCores_g   -q   -t  -N 1  -L 25   --phred33   --end-to-end    -x $Bowtie2_index_g    -U $input_g/$temp.fastq       -S $Bowtie_g/$temp.sam    >>$Bowtie_g/$temp.runLog  2>&1");
}
}  ## End Bowtie2
&myQC_BAM_1($Bowtie_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $subread_g  = "$output_g/5_Subread";
&myMakeDir($subread_g);
{ ## Start subread
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using Subread ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say   "\t......$pairedEnd_g[$i]";
        say   "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$subread_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("subread-align  -T $numCores_g  -I 20  -B 1  -M 6   --SAMoutput  -d 50  -D 600   -i $Subread_index_g   -r $input_g/$end1.fastq   -R  $input_g/$end2.fastq   -o  $subread_g/$temp.sam   -t 1  >>$subread_g/$temp.runLog  2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("subread-align  -T $numCores_g  -I 20  -B 1  -M 6   --SAMoutput   -i $Subread_index_g    -r $input_g/$temp.fastq    -o $subread_g/$temp.sam   -t 1    >>$subread_g/$temp.runLog   2>&1");
}
} ## End subread
&myQC_BAM_1($subread_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
&myQC_BAM_2($BWA2_g);
&myQC_BAM_2($BWA_g);
&myQC_BAM_2($Bowtie2_g);
&myQC_BAM_2($Bowtie_g);
&myQC_BAM_2($subread_g);
###################################################################################################################################################################################################



 

###################################################################################################################################################################################################
my $BBMap_g  = "$output_g/6_BBMap";
&myMakeDir($BBMap_g);
{ ########## Start BBMap
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using BBMap ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]\n";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$BBMap_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("bbmap.sh     path=$BBMap_index_g       out=$BBMap_g/$temp.sam  maxindel=20  minid=0.9   ambiguous=random   threads=$numCores_g   in=$input_g/$end1.fastq  in2=$input_g/$end2.fastq    >>$BBMap_g/$temp.runLog   2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\n\t......$singleEnd_g[$i]\n";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("bbmap.sh      path=$BBMap_index_g        out=$BBMap_g/$temp.sam   maxindel=20  minid=0.9  ambiguous=random   threads=$numCores_g   in=$input_g/$temp.fastq    >>$BBMap_g/$temp.runLog   2>&1");
}
}  ########## End BBMap
&myQC_BAM_1($BBMap_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $GSNAP_g  = "$output_g/7_GSNAP";
&myMakeDir($GSNAP_g);
{ ########## Start GSNAP
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using GSNAP ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]\n";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$GSNAP_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("gsnap   --db=$GSNAP_index_g    --nthreads=$numCores_g    --format=sam    --output-file=$GSNAP_g/$temp.sam   $input_g/$end1.fastq  $input_g/$end2.fastq    >>$GSNAP_g/$temp.runLog   2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\n\t......$singleEnd_g[$i]\n";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("gsnap   --db=$GSNAP_index_g    --nthreads=$numCores_g    --format=sam    --output-file=$GSNAP_g/$temp.sam       $input_g/$temp.fastq    >>$GSNAP_g/$temp.runLog   2>&1");
}
}  ########## End GSNAP
&myQC_BAM_1($GSNAP_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $Novoalign_g  = "$output_g/8_Novoalign";
&myMakeDir($Novoalign_g);
{ ########## Start Novoalign
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using Novoalign ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq"  eq  $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$Novoalign_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("novoalign  -d $Novoalign_index_g      -f $input_g/$end1.fastq  $input_g/$end2.fastq    -o SAM     >$Novoalign_g/$temp.sam ");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("novoalign  -d $Novoalign_index_g      -f $input_g/$temp.fastq     -o SAM     >$Novoalign_g/$temp.sam ");
}
}  ########## End Novoalign
&myQC_BAM_1($Novoalign_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $Stampy_g  = "$output_g/9_Stampy";
&myMakeDir($Stampy_g);
{ ########## Start Stampy
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using Stampy ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq"  eq  $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$Stampy_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("stampy.py  --genome=$Stampy_index_g   --hash=$Stampy_index_g   --threads=$numCores_g   --bamkeepgoodreads  --map=$BWA2_g/$temp.bam    --outputformat=sam    --output=$Stampy_g/$temp.sam   >> $Stampy_g/$temp.runLog   2>&1 ");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\t......$singleEnd_g[$i]";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("stampy.py  --genome=$Stampy_index_g   --hash=$Stampy_index_g   --threads=$numCores_g   --bamkeepgoodreads  --map=$BWA2_g/$temp.bam    --outputformat=sam    --output=$Stampy_g/$temp.sam   >> $Stampy_g/$temp.runLog   2>&1 ");    
}
}  ########## End Stampy
&myQC_BAM_1($Stampy_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
my $NGM2_g  = "$output_g/10_Trim_NGM";
&myMakeDir($NGM2_g);
{ ########## Start NGM
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using NGM ......";
my $inputDir2 = "2-mergedFASTQ";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]\n";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$NGM2_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("ngm   -r $NGM_index_g    -t $numCores_g     -1 $inputDir2/$end1.fastq  -2 $inputDir2/$end2.fastq    -o $NGM2_g/$temp.sam    >> $NGM2_g/$temp.runLog   2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\n\t......$singleEnd_g[$i]\n";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("ngm   -r $NGM_index_g    -t $numCores_g     -q $inputDir2/$temp.fastq   -o $NGM2_g/$temp.sam    >> $NGM2_g/$temp.runLog   2>&1");
}
}  ########## End NGM
&myQC_BAM_1($NGM2_g);
###################################################################################################################################################################################################




 
###################################################################################################################################################################################################
my $NGM_g  = "$output_g/11_NGM";
&myMakeDir($NGM_g);
{ ########## Start NGM
say   "\n\n\n\n\n\n##################################################################################################";
say   "Mapping reads to the reference genome by using NGM ......";
for (my $i=0; $i<=$#pairedEnd_g; $i=$i+2) {
        say    "\t......$pairedEnd_g[$i]";
        say    "\t......$pairedEnd_g[$i+1]\n";
        $pairedEnd_g[$i]   =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_1\.fastq$/   or  die;
        $pairedEnd_g[$i+1] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))_2\.fastq$/   or  die;
        my $temp = $1;
        my $end1 = $temp."_1";
        my $end2 = $temp."_2";
        ("$end2.fastq" eq $pairedEnd_g[$i+1])  or  die;
        open(tempFH, ">>", "$NGM_g/paired-end-files.txt")  or  die;
        say  tempFH  "$end1,  $end2\n";
        system("ngm   -r $NGM_index_g    -t $numCores_g     -1 $input_g/$end1.fastq  -2 $input_g/$end2.fastq    -o $NGM_g/$temp.sam    >> $NGM_g/$temp.runLog   2>&1");
}
for (my $i=0; $i<=$#singleEnd_g; $i++) {
        say   "\n\t......$singleEnd_g[$i]\n";
        $singleEnd_g[$i] =~ m/^((\d+)_($pattern_g)_(Rep[1-9]))\.fastq$/   or  die;
        my $temp = $1;
        system("ngm   -r $NGM_index_g    -t $numCores_g     -q $input_g/$temp.fastq   -o $NGM_g/$temp.sam    >> $NGM_g/$temp.runLog   2>&1");
}
}  ########## End NGM
&myQC_BAM_1($NGM_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
&myQC_BAM_2($BBMap_g);
&myQC_BAM_2($GSNAP_g);
&myQC_BAM_2($Novoalign_g);
&myQC_BAM_2($Stampy_g);
&myQC_BAM_2($NGM2_g);
&myQC_BAM_2($NGM_g);

&myQC_BAM_3($BWA2_g);
&myQC_BAM_3($BWA_g);
&myQC_BAM_3($Bowtie2_g);
&myQC_BAM_3($Bowtie_g);
&myQC_BAM_3($subread_g);
&myQC_BAM_3($BBMap_g);
&myQC_BAM_3($GSNAP_g);
&myQC_BAM_3($Novoalign_g);
&myQC_BAM_3($Stampy_g);
&myQC_BAM_3($NGM2_g);
&myQC_BAM_3($NGM_g);

&myQC_BAM_4($BWA2_g);
&myQC_BAM_4($BWA_g);
&myQC_BAM_4($Bowtie2_g);
&myQC_BAM_4($Bowtie_g);
&myQC_BAM_4($subread_g);
&myQC_BAM_4($BBMap_g);
&myQC_BAM_4($GSNAP_g);
&myQC_BAM_4($Novoalign_g);
&myQC_BAM_4($Stampy_g);
&myQC_BAM_4($NGM2_g);
&myQC_BAM_4($NGM_g);
###################################################################################################################################################################################################





###################################################################################################################################################################################################
say   "\n\n\n\n\n\n##################################################################################################";
say   "\tJob Done! Cheers! \n\n\n\n\n";





## END
