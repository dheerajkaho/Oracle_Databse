function  writeJson(
         topic   varchar2,
         theData json
      ) return  varchar2 is
         tempClob          CLOB;
         fullLength        pls_integer;
         currentPosition   pls_integer := 1;
         chunkSize         pls_integer := 20000;
         theBuffer         varchar2(20000);

         fHandle           utl_file.file_type;
         fName             varchar2(60);
         eolAt             pls_integer;

      begin
         dbms_lob.createtemporary(tempClob, true, dbms_lob.session);
         json_printer.pretty_print(theData, true, tempClob);
         dbms_lob.append(tempClob, chr(10));
         fullLength    := dbms_lob.getlength(tempClob);
         dbms_output.put_line('Length: ' || fullLength);

         fName         := topic || '_' || dbms_random.string('U', 60-length(topic||'_.json')) || '.json';
         dbms_output.put_line('fName: ' || fName);

         fHandle       := utl_file.fopen('INTERFACE_DIR', fName, 'w', 32767);
         while currentPosition < fullLength
         loop
            dbms_output.put_line(currentPosition || '/' || fullLength);

            theBuffer := dbms_lob.substr(tempClob, chunkSize, currentPosition);

            eolAt    := instr(theBuffer, chr(10), -1);

            if eolAt > 0 then
               theBuffer   := substr(theBuffer, 1, eolAt-1);
            end if;

            if theBuffer is not null then
               dbms_output.put('Writing...');
               utl_file.put_line(fHandle, theBuffer);
               dbms_output.put_line('Flushing...');
               utl_file.fflush(fHandle);
            else
               dbms_output.put_line('Yeah, no.');
            end if;


            --dbms_output.put_line('data extracted.');

            --exit when theBuffer is null;

            --dbms_output.put_line('Pre Write.');

            --utl_file.put(fHandle, theBuffer);
            --utl_file.put(fHandle, dbms_lob.substr(tempClob, chunkSize, currentPosition));
            --dbms_output.put_line('Flush.');
            --utl_file.fflush(fHandle);

            dbms_output.put_line('Post Write.');

            currentPosition := currentPosition + length(theBuffer); --chunkSize;
         end loop;

         --dbms_output.put_line('New Line.');
         --utl_file.new_line(fHandle);
         --dbms_output.put_line('Force flush.');
         --utl_file.fflush(fHandle);


         dbms_output.put_line('Close.');
         utl_file.fclose(fHandle);

         return  fName;
      exception
         when utl_file.invalid_path then
           return 'ERROR: File location or filename was invalid.';
         when utl_file.invalid_mode then
           return 'ERROR: The open_mode parameter in FOPEN was invalid.';
         when utl_file.invalid_filehandle then
           return 'ERROR: The file handle was invalid.';
         when utl_file.invalid_operation then
           return 'ERROR: The file could not be opened or operated on as requested.';
         when utl_file.read_error then
           return 'ERROR: An operating system error occurred during the read operation.';
         when utl_file.write_error then
           return 'ERROR: An operating system error occurred during the write operation.';
         when utl_file.internal_error then
           return 'ERROR: An unspecified error in PL/SQL.';
         when others then
            dbms_output.put_line(SQLERRM);
           return 'ERROR: PL/SQL error.';
      end writeJson;