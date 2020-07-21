#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>



int main(int argc,
         char *argv[])
{
    // Chack number of argument
    int narg = 5;
    if (argc != narg + 1)
    {
        printf("arguments must be %d.\n", narg);
        printf("./make_binning_lc.out inputfile_1(mjd, mjd_err, fx, fx_err) outputfile_1 epoch(mjd) bin_size(day) number_of_line_in_inputfile_1 > -.log\n");
        exit(1);
    }

    // Read arguments
    int iarg = 1;
    char *input_file_1 = argv[iarg];
    iarg ++;
    char *output_file_1 = argv[iarg];
    iarg ++;
    double epoch_mjd = atof(argv[iarg]);
    iarg ++;
    double bin_size = atof(argv[iarg]);
    iarg ++;
    int number_line_fi1 = atoi(argv[iarg]);
    iarg ++;



    //////////
    int number_line_fi1_p = number_line_fi1 + 10;
    //////////



    // Chack input file
    FILE *fi_1;
    if ((fi_1 = fopen(input_file_1, "r")) == NULL)
    {
        printf("Can not open %s.\n", input_file_1);
        exit(1);
    }
    printf("******************************\n"); // * 30
    printf("Input file 1(%s).\n", input_file_1);
    printf("******************************\n"); // * 30
    printf("\n");



    // Chack output file
    FILE *fo_1;
    if ((fo_1 = fopen(output_file_1, "w")) == NULL)
    {
        printf("Can not open %s.\n", output_file_1);
        exit(1);
    }
    printf("******************************\n"); // * 30
    printf("Output file 1(%s).\n", output_file_1);
    printf("******************************\n"); // * 30
    printf("\n");



    // Read values in input file 1
    char ss[200];
    double mjd[number_line_fi1_p];
    double mjd_err[number_line_fi1_p];
    double flux[number_line_fi1_p];
    double flux_err[number_line_fi1_p];

    int i_val = 0;
    printf("Input parameters in input file 1\n");
    while (fgets(ss, sizeof(ss), fi_1) != NULL)
    {
        // printf("%d\n", i_val); // dbg
        ss[strlen(ss)-1] = '\0';
        // printf("%d\n", (int)strlen(ss)); // dbg, A warning is happened in compile when (int) is not exist.
        // printf("input : %s\n", ss); // dbg

        sscanf(ss, "%lf %lf %lf %lf",
               &mjd[i_val],
               &mjd_err[i_val],
               &flux[i_val],
               &flux_err[i_val]);

        printf("%.15e %.15e %.10e %.10e\n",
               mjd[i_val],
               mjd_err[i_val],
               flux[i_val],
               flux_err[i_val]);

        i_val++;
    }

    printf("\n\n\n");

    int n_line = i_val;

    fclose(fi_1);



    // search mjd_min
    i_val = 0;
    double mjd_min = mjd[0];
    double mjd_max = mjd[0];
    for (i_val = 0; i_val < n_line; i_val++)
    {
        if (mjd_min > mjd[i_val])
        {
            mjd_min = mjd[i_val];
        }

        if (mjd_max < mjd[i_val])
        {
            mjd_max = mjd[i_val];
        }
    }



    // check epoch mjd
    if (epoch_mjd > mjd_min)
    {
        printf("The input epoch MJD should be smaller than start mjd.\n");
        printf("Please change epoch mjd.\n");
        exit(1);
    }



    //////////
    int number_line_fi1_sum_p = (int)floor((mjd_max - epoch_mjd) / bin_size) + 20;
    //////////



    // make binning light curve
    double sum_bin_mjd_min[number_line_fi1_sum_p];
    double sum_bin_mjd_max[number_line_fi1_sum_p];
    double sum_bin_flux[number_line_fi1_sum_p];
    double sum_bin_flux_err[number_line_fi1_sum_p];
    int number_in_bin[number_line_fi1_sum_p];
    int bin_number;
    int bin_number_max = 0;
    int bin_number_min = number_line_fi1_sum_p;
    double offset_mjd;

    // initialization
    i_val = 0;
    for (i_val = 0; i_val < number_line_fi1_sum_p; i_val++)
    {
        sum_bin_mjd_min[i_val] = mjd_max;
        sum_bin_mjd_max[i_val] = mjd_min;
        sum_bin_flux[i_val] = 0.0;
        sum_bin_flux_err[i_val] = 0.0;
        number_in_bin[i_val] = 0;

        /* printf("i_val : %d sum_bin_flux : %.6e sum_bin_flux_err : %.6e number_in_bin %d sum_bin_mjd_min : %.10e sum_bin_mjd_max : %.10e\n",
               i_val,
               sum_bin_flux[i_val],
               sum_bin_flux_err[i_val],
               number_in_bin[i_val],
               sum_bin_mjd_min[i_val],
               sum_bin_mjd_max[i_val]); // dbg */
    }

    // printf("\n"); // dbg

    // calculate sum_bin_flux and sum_bin_flux_err
    i_val = 0;
    for (i_val = 0; i_val < n_line; i_val++)
    {
        offset_mjd = (mjd[i_val] - epoch_mjd) / bin_size;
        bin_number = (int)floor(offset_mjd);
        number_in_bin[bin_number] = number_in_bin[bin_number] + 1;

        printf("offset_mjd : %.10e bin_number : %d number_in_bin : %d\n",
               offset_mjd,
               bin_number,
               number_in_bin[bin_number]); // dbg

        sum_bin_flux[bin_number] = sum_bin_flux[bin_number] + (flux[i_val] / pow(flux_err[i_val], 2.0));
        sum_bin_flux_err[bin_number] = sum_bin_flux_err[bin_number] + (1.0 / pow(flux_err[i_val], 2.0));

        printf("sum_bin_flux : %.10e sum_bin_flux_err : %.10e\n",
               sum_bin_flux[bin_number],
               sum_bin_flux_err[bin_number]); // dbg

        if (bin_number > bin_number_max)
        {
            bin_number_max = bin_number;
            // printf("bin_number_max : %d\n", bin_number_max); // dbg
        }

        if (bin_number < bin_number_min)
        {
            bin_number_min = bin_number;
            // printf("bin_number_min : %d\n", bin_number_min); // dbg
        }

        if (sum_bin_mjd_min[bin_number] > mjd[i_val])
        {
            sum_bin_mjd_min[bin_number] = mjd[i_val] - mjd_err[i_val];
        }

        if (sum_bin_mjd_max[bin_number] < mjd[i_val])
        {
            sum_bin_mjd_max[bin_number] = mjd[i_val] + mjd_err[i_val];
        }

        printf("sum_bin_mjd_min : %.10e sum_bin_mjd_max %.10e\n",
               sum_bin_mjd_min[bin_number],
               sum_bin_mjd_max[bin_number]); // dbg

        printf("\n"); // dbg
    }

    // calculate average flux and flux error
    double average_flux;
    double average_flux_err_n2;
    double average_flux_err;
    double average_mjd;
    double average_mjd_err;
    i_val = 0;
    for (i_val = bin_number_min; i_val <= bin_number_max; i_val++)
    {
        if (number_in_bin[i_val] > 0)
        {
            average_flux = sum_bin_flux[i_val] / sum_bin_flux_err[i_val];
            average_flux_err_n2 = sum_bin_flux_err[i_val];
            average_flux_err = 1.0 / pow(average_flux_err_n2, 0.5);
            average_mjd = (sum_bin_mjd_max[i_val] + sum_bin_mjd_min[i_val]) / 2.0;
            average_mjd_err = (sum_bin_mjd_max[i_val] - sum_bin_mjd_min[i_val]) / 2.0;

            fprintf(fo_1, "%.15e %.15e %.10e %.10e !number_in_bin : %d\n", average_mjd, average_mjd_err, average_flux, average_flux_err, number_in_bin[i_val]);
        }
    }

    printf("n_line : %d number_line_fi1_p %d\n",
           n_line,
           number_line_fi1_p);

    printf("bin_number_min : %d bin_number_max : %d number_line_fi1_sum_p : %d\n",
           bin_number_min,
           bin_number_max,
           number_line_fi1_sum_p);

    fclose(fo_1);

    return 0;
}
