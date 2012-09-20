
import java.io.*;
import java.util.*;

public class DataExtractor
{
	public static void main(String args[]) throws Exception
	{
                
		if(args.length < 1)
		{
			System.out.println("Where is the input file?");
			System.exit(1);
		}

		String inputFilename = args[0];
		File inputFile = new File(inputFilename);
		String outputFilename = inputFile.getName();
		if(args.length > 1)
		{
			outputFilename = args[1];
		}

		File outputFile127 = new File(outputFilename+".127");
		File outputFile2k= new File(outputFilename+".2k");

		Scanner scan = new Scanner(inputFile);
		PrintWriter pw127 = new PrintWriter(outputFile127);
		PrintWriter pw2k = new PrintWriter(outputFile2k);
		PrintWriter currentWriter = null;

		String line;
		while(scan.hasNextLine())
		{
			line = scan.nextLine();
			if(line.contains("[put->"))
			{
				if(line.contains("text127"))
				{
					currentWriter = pw127;
				}
				if(line.contains("text2k"))
				{
					currentWriter = pw2k;
				}
			}
			currentWriter.println(line);
            currentWriter.flush();
		}

		scan.close();
		pw127.close();
		pw2k.close();

		System.out.println(outputFile127.getAbsolutePath());
		System.out.println(outputFile2k.getAbsolutePath());
	}
    
    public static String[] extract(String args[]) throws Exception
	{
                
		if(args.length < 1)
		{
			System.out.println("Where is the input file?");
			System.exit(1);
		}

		String inputFilename = args[0];
		File inputFile = new File(inputFilename);
		String outputFilename = inputFile.getName();
		if(args.length > 1)
		{
			outputFilename = args[1];
		}

		File outputFile127 = new File(outputFilename+".127");
		File outputFile2k= new File(outputFilename+".2k");

		Scanner scan = new Scanner(inputFile);
		PrintWriter pw127 = new PrintWriter(outputFile127);
		PrintWriter pw2k = new PrintWriter(outputFile2k);
		PrintWriter currentWriter = null;

		String line;
		while(scan.hasNextLine())
		{
			line = scan.nextLine();
			if(line.contains("[put->"))
			{
				if(line.contains("text127"))
				{
					currentWriter = pw127;
				}
				if(line.contains("text2k"))
				{
					currentWriter = pw2k;
				}
			}
			currentWriter.println(line);
            currentWriter.flush();
		}

		scan.close();
		pw127.close();
		pw2k.close();

        String[] result = new String[2];
		result[0] = outputFile127.getAbsolutePath();
		result[1] = outputFile2k.getAbsolutePath();
        
        return result;
	}
}