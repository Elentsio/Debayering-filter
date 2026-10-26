library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dvlsi_lab6_top is
  port (
        DDR_cas_n         : inout STD_LOGIC;
        DDR_cke           : inout STD_LOGIC;
        DDR_ck_n          : inout STD_LOGIC;
        DDR_ck_p          : inout STD_LOGIC;
        DDR_cs_n          : inout STD_LOGIC;
        DDR_reset_n       : inout STD_LOGIC;
        DDR_odt           : inout STD_LOGIC;
        DDR_ras_n         : inout STD_LOGIC;
        DDR_we_n          : inout STD_LOGIC;
        DDR_ba            : inout STD_LOGIC_VECTOR(2 downto 0);
        DDR_addr          : inout STD_LOGIC_VECTOR(14 downto 0);
        DDR_dm            : inout STD_LOGIC_VECTOR(3 downto 0);
        DDR_dq            : inout STD_LOGIC_VECTOR(31 downto 0);
        DDR_dqs_n         : inout STD_LOGIC_VECTOR(3 downto 0);
        DDR_dqs_p         : inout STD_LOGIC_VECTOR(3 downto 0);
        FIXED_IO_mio      : inout STD_LOGIC_VECTOR(53 downto 0);
        FIXED_IO_ddr_vrn  : inout STD_LOGIC;
        FIXED_IO_ddr_vrp  : inout STD_LOGIC;
        FIXED_IO_ps_srstb : inout STD_LOGIC;
        FIXED_IO_ps_clk   : inout STD_LOGIC;
        FIXED_IO_ps_porb  : inout STD_LOGIC
  );
end entity;

architecture arch of dvlsi_lab6_top is

  component debayer_top
    generic (
        IMAGE_WIDTH  : integer := 32
    );
    Port (
        col_out        : out integer range 0 to IMAGE_WIDTH - 1;
        row_out        : out integer range 0 to IMAGE_WIDTH - 1;
        clk            : in  std_logic;
        rst_n          : in  std_logic;
        valid_in       : in  std_logic;
        s_axis_tready  : out std_logic;
        new_image      : in  std_logic;
        pixel_in       : in  std_logic_vector(7 downto 0);
        m_tready       : in  std_logic;
        valid_out      : out std_logic;
        image_finished : out std_logic;
        R              : out std_logic_vector(7 downto 0);
        G              : out std_logic_vector(7 downto 0);
        B              : out std_logic_vector(7 downto 0)
    );
  end component;

  component design_1_wrapper is
    port (
      DDR_cas_n, DDR_cke, DDR_ck_n, DDR_ck_p, DDR_cs_n,
      DDR_reset_n, DDR_odt, DDR_ras_n, DDR_we_n : inout STD_LOGIC;

      DDR_ba            : inout STD_LOGIC_VECTOR(2 downto 0);
      DDR_addr          : inout STD_LOGIC_VECTOR(14 downto 0);
      DDR_dm            : inout STD_LOGIC_VECTOR(3 downto 0);
      DDR_dq            : inout STD_LOGIC_VECTOR(31 downto 0);
      DDR_dqs_n         : inout STD_LOGIC_VECTOR(3 downto 0);
      DDR_dqs_p         : inout STD_LOGIC_VECTOR(3 downto 0);

      FIXED_IO_mio      : inout STD_LOGIC_VECTOR(53 downto 0);
      FIXED_IO_ddr_vrn  : inout STD_LOGIC;
      FIXED_IO_ddr_vrp  : inout STD_LOGIC;
      FIXED_IO_ps_srstb : inout STD_LOGIC;
      FIXED_IO_ps_clk   : inout STD_LOGIC;
      FIXED_IO_ps_porb  : inout STD_LOGIC;

      ACLK                                : out STD_LOGIC;
      ARESETN                             : out STD_LOGIC_VECTOR(0 to 0);

      M_AXIS_TO_ACCELERATOR_tdata         : out STD_LOGIC_VECTOR(7 downto 0);
      M_AXIS_TO_ACCELERATOR_tkeep         : out STD_LOGIC_VECTOR(0 to 0);
      M_AXIS_TO_ACCELERATOR_tlast         : out STD_LOGIC;
      M_AXIS_TO_ACCELERATOR_tready        : in  STD_LOGIC;
      M_AXIS_TO_ACCELERATOR_tvalid        : out STD_LOGIC;

      S_AXIS_S2MM_FROM_ACCELERATOR_tdata  : in  STD_LOGIC_VECTOR(31 downto 0);
      S_AXIS_S2MM_FROM_ACCELERATOR_tkeep  : in  STD_LOGIC_VECTOR(3 downto 0);
      S_AXIS_S2MM_FROM_ACCELERATOR_tlast  : in  STD_LOGIC;
      S_AXIS_S2MM_FROM_ACCELERATOR_tready : out STD_LOGIC;
      S_AXIS_S2MM_FROM_ACCELERATOR_tvalid : in  STD_LOGIC
    );
  end component;

  signal aclk    : std_logic;
  signal aresetn : std_logic_vector(0 to 0);

  signal s_tdata  : std_logic_vector(7 downto 0);
  signal s_tkeep  : std_logic_vector(0 to 0);
  signal s_tlast  : std_logic;
  signal s_tready : std_logic;
  signal s_tvalid : std_logic;

  signal m_tdata      : std_logic_vector(31 downto 0);
  signal m_tlast      : std_logic;
  signal m_tready_sig : std_logic;
  signal m_tvalid     : std_logic;

  signal filter_R : std_logic_vector(7 downto 0);
  signal filter_G : std_logic_vector(7 downto 0);
  signal filter_B : std_logic_vector(7 downto 0);

  signal first_pixel    : std_logic := '1';
  signal new_image_flag : std_logic := '1';

  signal valid_combined : std_logic;

begin

  valid_combined <= s_tvalid and s_tready;

  process(aclk)
  begin
    if rising_edge(aclk) then
      if aresetn(0) = '0' then
        first_pixel <= '1';
      elsif s_tvalid = '1' and s_tready = '1' then
        if s_tlast = '1' then
          first_pixel <= '1';
        else
          first_pixel <= '0';
        end if;
      end if;
    end if;
  end process;

  new_image_flag <= first_pixel and s_tvalid and s_tready;

  m_tdata <= "00000000" & filter_R & filter_G & filter_B;

  PROCESSING_SYSTEM_INSTANCE : design_1_wrapper
    port map (
      DDR_cas_n   => DDR_cas_n,
      DDR_cke     => DDR_cke,
      DDR_ck_n    => DDR_ck_n,
      DDR_ck_p    => DDR_ck_p,
      DDR_cs_n    => DDR_cs_n,
      DDR_reset_n => DDR_reset_n,
      DDR_odt     => DDR_odt,
      DDR_ras_n   => DDR_ras_n,
      DDR_we_n    => DDR_we_n,

      DDR_ba    => DDR_ba,
      DDR_addr  => DDR_addr,
      DDR_dm    => DDR_dm,
      DDR_dq    => DDR_dq,
      DDR_dqs_n => DDR_dqs_n,
      DDR_dqs_p => DDR_dqs_p,

      FIXED_IO_mio      => FIXED_IO_mio,
      FIXED_IO_ddr_vrn  => FIXED_IO_ddr_vrn,
      FIXED_IO_ddr_vrp  => FIXED_IO_ddr_vrp,
      FIXED_IO_ps_srstb => FIXED_IO_ps_srstb,
      FIXED_IO_ps_clk   => FIXED_IO_ps_clk,
      FIXED_IO_ps_porb  => FIXED_IO_ps_porb,

      ACLK    => aclk,
      ARESETN => aresetn,

      M_AXIS_TO_ACCELERATOR_tdata  => s_tdata,
      M_AXIS_TO_ACCELERATOR_tkeep  => s_tkeep,
      M_AXIS_TO_ACCELERATOR_tlast  => s_tlast,
      M_AXIS_TO_ACCELERATOR_tready => s_tready,
      M_AXIS_TO_ACCELERATOR_tvalid => s_tvalid,

      S_AXIS_S2MM_FROM_ACCELERATOR_tdata  => m_tdata,
      S_AXIS_S2MM_FROM_ACCELERATOR_tkeep  => "1111",
      S_AXIS_S2MM_FROM_ACCELERATOR_tlast  => m_tlast,
      S_AXIS_S2MM_FROM_ACCELERATOR_tready => m_tready_sig,
      S_AXIS_S2MM_FROM_ACCELERATOR_tvalid => m_tvalid
    );

  DEBAYER_FILTER_INSTANCE : debayer_top
    generic map (
      IMAGE_WIDTH => 32
    )
    port map (
      col_out        => open,
      row_out        => open,

      clk            => aclk,
      rst_n          => aresetn(0),

      valid_in       => valid_combined,
      s_axis_tready  => s_tready,

      new_image      => new_image_flag,
      pixel_in       => s_tdata,

      m_tready       => m_tready_sig,

      valid_out      => m_tvalid,
      image_finished => m_tlast,

      R              => filter_R,
      G              => filter_G,
      B              => filter_B
    );

end architecture;