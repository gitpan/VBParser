
package Language::VBParser;

require 5.005;
use strict;
use warnings;
use vars qw ( $VERSION );

$VERSION = '0.01';

use Parse::RecDescent;

local $/;

  # Définition de la grammaire
  
my $grammar = q {
		  
		list: 	  <leftop: <matchrule:$arg{rule}> /$arg{sep}/ <matchrule:$arg{rule}> >
		
		prg: bloc(s)
	
		
		bloc: procedure
		  {{ sub=>$item{procedure} }}
		      |function
		  {{ function=>$item{function} }}
		      |propertyset
		  {{ property=>$item{propertyset} }}
		      |propertyget
		  {{ property=>$item{propertyget} }}
		      |propertylet
		  {{ property=>$item{propertylet} }}
		      |empty
		      |VBOptions
		      |comment    
		      |attribute
		      |line
		      
		VBOptions: /BEGIN/ option(s) /END\n/
		  {{ options=>$item{option} }}
		
		option: /(?!^END).*\n/
		   { $item[1] } 
		  
		attribute: 'Attribute ' attributename '=' attributevalue
		  {{  attribute=>{$item{attributename}=> $item{attributevalue} } }}
		
		attributename: /\w+/
		
		attributevalue: /[\w\"_]+/
		
		empty: /\s*\n/i
		  {{ emptyLine=>'' }}
		
		function:  scope 'Function' ident '(' list[rule=>'param',sep=>','] ')' /As/ typename ef 
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list}, type=>$item{typename} }}
		           |scope 'Function' ident '(' list[rule=>'param',sep=>','] ')' /As/ typename rawline(s) ef 
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} , type=>$item{typename} ,lines=>$item{rawline} }}
		           |scope 'Function' ident '()' /As/ typename ef 
				{{  scope=>$item{scope},name=>$item{ident} , type=>$item{typename} }}
		           |scope 'Function' ident '()' /As/ typename rawline(s) ef 
				{{  scope=>$item{scope},name=>$item{ident}, type=>$item{typename} ,lines=>$item{rawline} }}
		
		
		procedure: scope 'Sub' ident '(' list[rule=>'param',sep=>','] ')' ep
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} }}
			   |scope 'Sub' ident '(' list[rule=>'param',sep=>','] ')' rawline(s) ep
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} ,lines=>$item{rawline} }}
                           |scope 'Sub' ident '()' ep
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{line} }}
                           |scope 'Sub' ident '()' rawline(s) ep
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{rawline} }}

		propertylet:scope 'Property' 'Let' ident '(' list[rule=>'param',sep=>','] ')' eprop
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} }}
			   |scope 'Property' 'Let' ident '(' list[rule=>'param',sep=>','] ')' rawline(s) eprop
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} ,lines=>$item{rawline} }}
                           |scope 'Property' 'Let' ident '()' eprop
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{line} }}
                           |scope 'Property' 'Let' ident '()' rawline(s) eprop
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{rawline} }}
 
 		propertyset:scope 'Property' 'Set' ident '(' list[rule=>'param',sep=>','] ')' eprop
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} }}
			   |scope 'Property' 'Set' ident '(' list[rule=>'param',sep=>','] ')' rawline(s) eprop
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} ,lines=>$item{rawline} }}
                           |scope 'Property' 'Set' ident '()' eprop
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{line} }}
                           |scope 'Property' 'Set' ident '()' rawline(s) eprop
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{rawline} }}
                
                propertyget:  scope 'Property' 'Get' ident '(' list[rule=>'param',sep=>','] ')' /As/ typename eprop
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list} , type=>$item{typename} }}
		           |scope 'Property' 'Get' ident '(' list[rule=>'param',sep=>','] ')' /As/ typename rawline(s) eprop 
				{{  scope=>$item{scope},name=>$item{ident}, param=>$item{list}, type=>$item{typename} ,lines=>$item{rawline} }}
		           |scope 'Property' 'Get' ident '()' /As/ typename eprop
				{{  scope=>$item{scope},name=>$item{ident}, type=>$item{typename} }}
		           |scope 'Property' 'Get' ident '()' /As/ typename rawline(s) eprop
				{{  scope=>$item{scope},name=>$item{ident},lines=>$item{rawline}, type=>$item{typename} }}
		           
				
		param:	 /((ByVal)|(ByRef)|)/i ident 'As' typename
				{{ var=>$item{ident}, type=>$item{typename} }}

		scope:	 /((Private)|(Public)|)/i
		
		ident:	  /\w+/

		typename: /[\w\.]+/
		
		line: rawline
		   {{ line=>$prevline }}
		
		rawline: declaration
			|comment
		        |statement
		        
			 
		comment: /\'(.*)\n/i
		   {{ comment=>$item[1] }}
		
		declaration: 'Dim' list[rule=>'param',sep=>',']
		   {{ declaration=>$item{list} }}
		   
		statement: /^((?!\s*End ((Function)|(Sub)|(Property))).*)\n/i
                    { $prevline }
                       
		ef: /^End Function.*\n/i
		
		ep: /^End Sub.*\n/i
		   
		eprop: /^End Property.*\n/i
          
		
	     };

# Lecture de la grammaire au chargement du package

unless( $Parse::VB::parser = new Parse::RecDescent( $grammar ))
{
    die "La Grammaire est mauvaise \n";
}


sub inter
{
  
   my @Prg=@_;
   map { s/(.*) _.*/$1/g } @Prg;  # enleve les instruction sur plusieurs lignes, 
   				    # cette opération simplifie le travail du parser.
   my $l="";
   $l = join '',@Prg;
   $l=$Parse::VB::parser->prg( $l );
   
   # replace les bonnes lignes dans le résultat parsé
	for my $i (@$l)
	{
		if ($i->{line})
		{
			$i->{line}=$Prg[$i->{line}-1];
		};
		
		for my $j ('sub','function','property')
		{
			if ($i->{$j})
			{
				if (defined($i->{$j}->{lines}))
				{  #print "changement de ".$i->{$j}->{name}."\n";
					map { 	if (!ref($_)) {
						  $_=$Prg[$_-1];
					          };
					} @{$i->{$j}->{lines}};
				};		
			};
			
		};
	}
	
   return $l; # retourne la référence au code VB parsé
}
1; # bon chargement du package



1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

VB - Perl extension for parsing VB source files

=head1 SYNOPSIS

  use Language::VBParser;
  use Data::Dumper;

  my $filename = 'C:\temp\ModeAutomatique.cls';
  # Read VB source File
  open (TEMP,$filename );
  my @projet=<TEMP>;
  close TEMP;

  # parsing

   my $r = Language::VBParser::inter(@projet); 
   print Data::Dumper->Dump([$r]);


      This return something like that:
      
      
$VAR1 = [
          {
            'line' => 'VERSION 1.0 CLASS
'
          },
          {
            'options' => [
                           'MultiUse = -1  \'True
',
                           'Persistable = 0  \'NotPersistable
',
                           'DataBindingBehavior = 0  \'vbNone
',
                           'DataSourceBehavior  = 0  \'vbNone
',
                           'MTSTransactionMode  = 0  \'NotAnMTSObject
'
                         ]
          },
          {
            'attribute' => {
                             'VB_Name' => '"ModeAutomatique"'
                           }
          },
          {
            'attribute' => {
                             'VB_GlobalNameSpace' => 'False'
                           }
          },
          {
            'attribute' => {
                             'VB_Creatable' => 'True'
                           }
          },
          {
            'attribute' => {
                             'VB_PredeclaredId' => 'False'
                           }
          },
          {
            'attribute' => {
                             'VB_Exposed' => 'True'
                           }
          },
          {
            'line' => 'Option Explicit
'
          },
          {
            'comment' => '\'@Date de création: 20/03/2001
'
          },
          {
            'comment' => '\'@Auteur: Freydiere Patrice
'
          },
          {
            'comment' => '\'@Résumé: Outil permettant l\'activation ou désactivation du mode automatique de la fiche attributaire
'
          },
          {
            'comment' => '\'@Description: Cet outil permet d\'activer ou de désactiver l\'affichage
'
          },
          {
            'comment' => '\' automatique de la fiche attributaire lors de la création d\'un
'
          },
          {
            'comment' => '\' nouvel objet
'
          },
          {
            'comment' => '\' Cet outil fonctionne avec l\'extension de l\'editeur AffichageAutoFiche
'
          },
          {
            'comment' => '\'@Commentaire: Nom du fichier Source Safe $Workfile: EH.cls $
'
          },
          {
            'comment' => '\' Dernière modification effectuée par $Author: Admin $
'
          },
          {
            'comment' => '\' Date dernière modification $Date: 6/02/01 14:08 $
'
          },
          {
            'comment' => '\' Version $Revision: 4 $
'
          },
          {
            'comment' => '\'@Structure de données utilisées:
'
          },
          {
            'comment' => '\'@Prérequis:
'
          },
          {
            'line' => 'Implements ICommand
'
          },
          {
            'line' => 'Dim mApplication As IApplication
'
          },
          {
            'line' => 'Dim mExtensionAffichageAutoFiche As AffichageAutoFiche
'
          },
          {
            'line' => 'Dim mPictureDisp As IPictureDisp
'
          },
          {
            'sub' => {
                       'scope' => 'Private',
                       'lines' => [
                                    '  Set mPictureDisp = LoadResPicture(101, vbResBitmap)
'
                                  ],
                       'name' => 'Class_Initialize'
                     }
          },
          {
            'sub' => {
                       'scope' => 'Private',
                       'lines' => [
                                    '   Set mApplication = Nothing
',
                                    '   Set mExtensionAffichageAutoFiche = Nothing
'
                                  ],
                       'name' => 'Class_Terminate'
                     }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'esriCore.OLE_HANDLE',
                            'lines' => [
                                         '   ICommand_Bitmap = mPictureDisp
'
                                       ],
                            'name' => 'ICommand_Bitmap'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'lines' => [
                                         '   ICommand_Caption = "Activation du Mode Fiche Automatique"
'
                                       ],
                            'name' => 'ICommand_Caption'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'lines' => [
                                         '   ICommand_Category = "Outils"
'
                                       ],
                            'name' => 'ICommand_Category'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'Boolean',
                            'lines' => [
                                         '   On Error GoTo EH
',
                                         '   If Not mApplication Is Nothing Then
',
                                         '      ICommand_Checked = mExtensionAffichageAutoFiche.ActiveFicheAuto
',
                                         '   End If
',
                                         'Exit Property
',
                                         'EH:
',
                                         '    Raise Err.Number, Err.Source & "ICommand_Checked", Err.Description
'
                                       ],
                            'name' => 'ICommand_Checked'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'Boolean',
                            'lines' => [
                                         '  If Not mApplication Is Nothing Then ICommand_Enabled = True
'
                                       ],
                            'name' => 'ICommand_Enabled'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'Long',
                            'name' => 'ICommand_HelpContextID'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'name' => 'ICommand_HelpFile'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'lines' => [
                                         '   ICommand_Message = MSG_MessageAffichageAutoFiche
'
                                       ],
                            'name' => 'ICommand_Message'
                          }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'lines' => [
                                         '   ICommand_Name = "Activation Mode Automatique"
'
                                       ],
                            'name' => 'ICommand_Name'
                          }
          },
          {
            'sub' => {
                       'scope' => 'Private',
                       'lines' => [
                                    '   mExtensionAffichageAutoFiche.ActiveFicheAuto = Not mExtensionAffichageAutoFiche.ActiveFicheAuto
'
                                  ],
                       'name' => 'ICommand_OnClick'
                     }
          },
          {
            'comment' => '\'@Nom:ICommand_OnCreate
'
          },
          {
            'sub' => {
                       'param' => [
                                    {
                                      'var' => 'hook',
                                      'type' => 'Object'
                                    }
                                  ],
                       'scope' => 'Private',
                       'lines' => [
                                    '   On Error GoTo EH
',
                                    '  If TypeOf hook Is IMxApplication Then
',
                                    '     Set mApplication = hook
',
                                    {
                                      'comment' => '\'Recherche de l\'editeur
'
                                    },
                                    {
                                      'declaration' => [
                                                         {
                                                           'var' => 'pUid',
                                                           'type' => 'IUID'
                                                         }
                                                       ]
                                    },
                                    '     Set pUid = New UID
',
                                    '     pUid = "esricore.Editor"
',
                                    {
                                      'declaration' => [
                                                         {
                                                           'var' => 'pEditor',
                                                           'type' => 'IEditor'
                                                         }
                                                       ]
                                    },
                                    '     Set pEditor = mApplication.FindExtensionByCLSID(pUid)
',
                                    {
                                      'comment' => '\' Recherche de l\'extension AffichageAutoFiche
'
                                    },
                                    {
                                      'declaration' => [
                                                         {
                                                           'var' => 'pUid2',
                                                           'type' => 'IUID'
                                                         }
                                                       ]
                                    },
                                    '     Set pUid2 = New UID
',
                                    '     pUid2 = "Outils.AffichageAutoFiche" \' CLSID de l\'extension d\'éditeur
',
                                    '     Set mExtensionAffichageAutoFiche = pEditor.FindExtension(pUid2)
',
                                    '     If mExtensionAffichageAutoFiche Is Nothing Then
',
                                    '        Set mApplication = Nothing \' désactivation de l\'outil
',
                                    '        Raise 550, "Outils", "Impossible de récupérer l\'extension AffichageAutoFiche"
',
                                    '     End If
',
                                    '  End If
',
                                    'Exit Sub
',
                                    'EH:
',
                                    '    Raise Err.Number, Err.Source & "ICommand_OnCreate", Err.Description
'
                                  ],
                       'name' => 'ICommand_OnCreate'
                     }
          },
          {
            'property' => {
                            'scope' => 'Private',
                            'type' => 'String',
                            'lines' => [
                                         '  ICommand_Tooltip = MSG_MessageAffichageAutoFiche
'
                                       ],
                            'name' => 'ICommand_Tooltip'
                          }
          }
        ];


  

=head1 DESCRIPTION

    VB parse a Visual Basic Source Files for different usage.
    Thanks to this module, people can make VB to Html documentation
    of the source files.
    It is also possible to check programming rules. (variable naming, declarations, comments..)

    VB recognize :
    	
    	Methods
    	Functions
    	Properties
    	Variable declaration


=head2 EXPORT

None by default.


=head1 AUTHOR

Patrice FREYDIERE, frett@iname.com

=head1 SEE ALSO

  RecDescent, a recursive parser

perl(1).

=cut
